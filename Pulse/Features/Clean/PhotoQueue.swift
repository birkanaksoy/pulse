import Foundation
import Photos
import Observation

/// A flat queue of PHAsset's the user is going to swipe through.
/// Order is deliberately weighted to give quick wins first:
///   1) Screenshots — boring, low-attachment, easy yes-deletes
///   2) Bursts (extras only — first kept)
///   3) Big videos (>100 MB)
///   4) Recent random photos (fallback)
@Observable
@MainActor
final class PhotoQueue {

    enum State: Equatable { case idle, loading, ready, denied }

    var state: State = .idle
    var assets: [PHAsset] = []

    func load() async {
        state = .loading
        let auth = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard auth == .authorized || auth == .limited else {
            state = .denied
            return
        }

        let collected: [PHAsset] = await Task.detached(priority: .userInitiated) {
            var seen = Set<String>()
            var out: [PHAsset] = []

            func add(_ list: PHFetchResult<PHAsset>, limit: Int? = nil) {
                var counter = 0
                list.enumerateObjects { asset, _, stop in
                    if seen.insert(asset.localIdentifier).inserted {
                        out.append(asset)
                        counter += 1
                        if let limit, counter >= limit { stop.pointee = true }
                    }
                }
            }

            // 1) Screenshots (no limit — usually 100–500)
            let ssOpts = PHFetchOptions()
            ssOpts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            ssOpts.predicate = NSPredicate(
                format: "(mediaSubtypes & %d) != 0",
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
            add(PHAsset.fetchAssets(with: .image, options: ssOpts))

            // 2) Burst extras (skip the first of each burst)
            let burstOpts = PHFetchOptions()
            burstOpts.predicate = NSPredicate(format: "burstIdentifier != nil")
            burstOpts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let bursts = PHAsset.fetchAssets(with: .image, options: burstOpts)
            var bursted: [String: [PHAsset]] = [:]
            bursts.enumerateObjects { a, _, _ in
                if let id = a.burstIdentifier { bursted[id, default: []].append(a) }
            }
            for (_, group) in bursted {
                for asset in group.dropFirst() {
                    if seen.insert(asset.localIdentifier).inserted {
                        out.append(asset)
                    }
                }
            }

            // 3) Big videos (>100 MB)
            let videos = PHAsset.fetchAssets(with: .video, options: nil)
            videos.enumerateObjects { v, _, _ in
                let bytes = PhotoCleaner.bytes(of: v)
                if bytes > 100 * 1024 * 1024, seen.insert(v.localIdentifier).inserted {
                    out.append(v)
                }
            }

            // 4) Fallback — newest photos until we have at least 50 items
            if out.count < 50 {
                let opts = PHFetchOptions()
                opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                opts.fetchLimit = 100
                add(PHAsset.fetchAssets(with: .image, options: opts), limit: 100)
            }

            return out
        }.value

        assets = collected
        state = .ready
    }
}
