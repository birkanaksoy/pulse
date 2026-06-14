import Photos
import Observation

struct VideoEntry: Identifiable, Equatable {
    let id: String        // localIdentifier
    let asset: PHAsset
    let bytes: Int64
    let duration: TimeInterval
}

@Observable
@MainActor
final class LargeVideoFinder {
    var videos: [VideoEntry] = []
    var isScanning = false

    var totalBytes: Int64 { videos.reduce(into: 0) { $0 += $1.bytes } }

    func scan() async {
        isScanning = true
        defer { isScanning = false }

        let auth = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard auth == .authorized || auth == .limited else { videos = []; return }

        let entries: [VideoEntry] = await Task.detached(priority: .userInitiated) {
            let fetch = PHAsset.fetchAssets(with: .video, options: nil)
            var out: [VideoEntry] = []
            fetch.enumerateObjects { asset, _, _ in
                let b = PhotoCleaner.bytes(of: asset)
                out.append(VideoEntry(
                    id: asset.localIdentifier,
                    asset: asset,
                    bytes: b,
                    duration: asset.duration
                ))
            }
            return out.sorted { $0.bytes > $1.bytes }
        }.value

        videos = entries
    }

    func consume(_ ids: Set<String>) {
        videos.removeAll { ids.contains($0.id) }
    }
}
