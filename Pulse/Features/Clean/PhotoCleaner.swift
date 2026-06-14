import Foundation
import Photos
import os.log

/// Real deletion via PhotoKit. iOS always shows a native confirmation prompt
/// before actually deleting — there's no way around that, which is exactly
/// what we want for an "honest cleaner".
@MainActor
enum PhotoCleaner {
    private static let log = Logger(subsystem: "app.pulse", category: "cleaner")

    /// Returns the real byte size of an asset via PHAssetResource metadata.
    nonisolated static func bytes(of asset: PHAsset) -> Int64 {
        var total: Int64 = 0
        for r in PHAssetResource.assetResources(for: asset) {
            if let n = r.value(forKey: "fileSize") as? NSNumber {
                total += n.int64Value
            }
        }
        return total
    }

    /// Deletes the given assets. iOS shows a system confirmation; if the user
    /// cancels, the closure receives `success=false`. On success we tally the
    /// freed bytes into BytesFreedTracker.
    static func delete(_ assets: [PHAsset]) async -> (success: Bool, freed: Int64) {
        guard !assets.isEmpty else { return (false, 0) }
        let totalBytes = assets.reduce(into: Int64(0)) { $0 += bytes(of: $1) }

        return await withCheckedContinuation { cont in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            } completionHandler: { ok, error in
                if let e = error { log.error("delete error: \(e.localizedDescription, privacy: .public)") }
                if ok { BytesFreedTracker.add(totalBytes) }
                cont.resume(returning: (ok, ok ? totalBytes : 0))
            }
        }
    }
}
