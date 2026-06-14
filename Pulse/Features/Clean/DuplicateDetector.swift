import Photos
import UIKit
import Observation

struct DuplicateGroup: Identifiable {
    let id = UUID()
    /// First asset is treated as the "best/keep" suggestion (we pick the first).
    let assets: [PHAsset]
    var bytes: Int64
    var savings: Int64 { bytes - PhotoCleaner.bytes(of: assets[0]) }
}

@Observable
@MainActor
final class DuplicateDetector {
    var groups: [DuplicateGroup] = []
    var isScanning = false
    var progress: Double = 0
    var totalSavings: Int64 {
        groups.reduce(into: 0) { $0 += $1.savings }
    }

    /// Hamming distance ≤ this counts as a duplicate group.
    private let threshold = 5

    func scan() async {
        isScanning = true
        progress = 0
        defer { isScanning = false }

        let auth = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard auth == .authorized || auth == .limited else {
            groups = []
            return
        }

        let fetch = PHAsset.fetchAssets(with: .image, options: nil)
        let total = fetch.count
        guard total > 0 else { groups = []; return }

        let mgr = PHCachingImageManager()
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .fastFormat
        opts.resizeMode = .fast
        opts.isSynchronous = false
        opts.isNetworkAccessAllowed = false

        var hashes: [(asset: PHAsset, hash: UInt64)] = []
        hashes.reserveCapacity(total)

        // Iterate batches off main to keep the UI snappy.
        let assets: [PHAsset] = await Task.detached(priority: .utility) {
            var out: [PHAsset] = []
            fetch.enumerateObjects { a, _, _ in out.append(a) }
            return out
        }.value

        for (i, asset) in assets.enumerated() {
            let img: UIImage? = await withCheckedContinuation { cont in
                mgr.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 64, height: 64),
                    contentMode: .aspectFill,
                    options: opts
                ) { image, _ in
                    cont.resume(returning: image)
                }
            }
            if let image = img, let h = PerceptualHash.aHash(image) {
                hashes.append((asset, h))
            }
            if i % 25 == 0 {
                progress = Double(i) / Double(total)
                await Task.yield()
            }
        }
        progress = 1.0

        // Cluster: O(n²) — fine for thousands; for tens of thousands use
        // band-bucketed LSH. Keeping simple for clarity.
        var clusters: [[Int]] = []
        var assigned = Set<Int>()
        for i in 0..<hashes.count {
            if assigned.contains(i) { continue }
            var cluster = [i]
            assigned.insert(i)
            for j in (i + 1)..<hashes.count {
                if assigned.contains(j) { continue }
                if PerceptualHash.hamming(hashes[i].hash, hashes[j].hash) <= threshold {
                    cluster.append(j)
                    assigned.insert(j)
                }
            }
            if cluster.count >= 2 { clusters.append(cluster) }
        }

        groups = clusters.map { idxs in
            let assets = idxs.map { hashes[$0].asset }
            let bytes = assets.reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) }
            return DuplicateGroup(assets: assets, bytes: bytes)
        }.sorted { $0.savings > $1.savings }
    }

    /// Removes a group from local state (used after the user confirms deletion).
    func consume(_ group: DuplicateGroup) {
        groups.removeAll { $0.id == group.id }
    }
}
