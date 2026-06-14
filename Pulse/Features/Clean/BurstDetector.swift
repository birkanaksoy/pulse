import Photos
import Observation

struct BurstGroup: Identifiable {
    let id: String     // burstIdentifier
    let assets: [PHAsset]
    var bytes: Int64
    /// Bytes freed if all but the first kept.
    var savings: Int64 { bytes - PhotoCleaner.bytes(of: assets[0]) }
}

@Observable
@MainActor
final class BurstDetector {
    var groups: [BurstGroup] = []
    var isScanning = false

    var totalSavings: Int64 { groups.reduce(into: 0) { $0 += $1.savings } }

    func scan() async {
        isScanning = true
        defer { isScanning = false }

        let auth = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard auth == .authorized || auth == .limited else { groups = []; return }

        let opts = PHFetchOptions()
        // iOS gives a per-burst-asset flag; we cluster by burstIdentifier.
        opts.predicate = NSPredicate(format: "burstIdentifier != nil")

        let fetch = await Task.detached(priority: .userInitiated) {
            PHAsset.fetchAssets(with: .image, options: opts)
        }.value

        var byID: [String: [PHAsset]] = [:]
        await Task.detached(priority: .userInitiated) {
            fetch.enumerateObjects { asset, _, _ in
                if let id = asset.burstIdentifier { byID[id, default: []].append(asset) }
            }
        }.value

        let detected: [BurstGroup] = byID.compactMap { (id, assets) in
            guard assets.count >= 2 else { return nil }
            let bytes = assets.reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) }
            return BurstGroup(id: id, assets: assets, bytes: bytes)
        }
        .sorted { $0.savings > $1.savings }

        groups = detected
    }

    func consume(_ group: BurstGroup) {
        groups.removeAll { $0.id == group.id }
    }
}
