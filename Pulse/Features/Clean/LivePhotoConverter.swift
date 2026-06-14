import Photos
import UIKit
import Observation

struct LivePhotoEntry: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    let bytes: Int64
    /// Estimated bytes after Live Photo video track is removed (~60% of total).
    var bytesAfter: Int64 { Int64(Double(bytes) * 0.4) }
    var savings: Int64 { bytes - bytesAfter }
}

@Observable
@MainActor
final class LivePhotoConverter {
    var entries: [LivePhotoEntry] = []
    var isScanning = false
    var isConverting = false
    var convertedBytes: Int64 = 0

    var totalSavings: Int64 { entries.reduce(into: 0) { $0 += $1.savings } }

    func scan() async {
        isScanning = true
        defer { isScanning = false }

        let auth = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard auth == .authorized || auth == .limited else { entries = []; return }

        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoLive.rawValue
        )

        let found: [LivePhotoEntry] = await Task.detached(priority: .userInitiated) {
            let fetch = PHAsset.fetchAssets(with: .image, options: opts)
            var out: [LivePhotoEntry] = []
            fetch.enumerateObjects { asset, _, _ in
                let b = PhotoCleaner.bytes(of: asset)
                out.append(LivePhotoEntry(id: asset.localIdentifier, asset: asset, bytes: b))
            }
            return out.sorted { $0.savings > $1.savings }
        }.value

        entries = found
    }

    /// Converts the selected Live Photos to stills by stripping the video
    /// portion via PHContentEditingOutput. iOS preserves the asset and updates
    /// it in place — no system confirmation needed since it's an edit.
    func convert(_ selected: [LivePhotoEntry]) async -> Int64 {
        isConverting = true
        defer { isConverting = false }

        var freed: Int64 = 0
        for entry in selected {
            if await convertOne(entry.asset) {
                freed += entry.savings
                entries.removeAll { $0.id == entry.id }
            }
        }
        BytesFreedTracker.add(freed)
        convertedBytes += freed
        return freed
    }

    private func convertOne(_ asset: PHAsset) async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = false
            asset.requestContentEditingInput(with: options) { input, _ in
                guard let input,
                      let imageURL = input.fullSizeImageURL,
                      let data = try? Data(contentsOf: imageURL) else {
                    cont.resume(returning: false); return
                }
                let output = PHContentEditingOutput(contentEditingInput: input)
                output.adjustmentData = PHAdjustmentData(
                    formatIdentifier: "app.pulse.livetostill",
                    formatVersion: "1.0",
                    data: Data()
                )
                do {
                    try data.write(to: output.renderedContentURL)
                } catch {
                    cont.resume(returning: false); return
                }
                PHPhotoLibrary.shared().performChanges {
                    let req = PHAssetChangeRequest(for: asset)
                    req.contentEditingOutput = output
                } completionHandler: { ok, _ in
                    cont.resume(returning: ok)
                }
            }
        }
    }
}
