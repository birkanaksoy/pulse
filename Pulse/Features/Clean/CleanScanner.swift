import Foundation
import Photos
import Observation

struct CleanCategory: Identifiable, Equatable {
    enum Kind: String { case screenshots, photos, videos }
    var id: Kind { kind }
    var kind: Kind
    var title: String
    var icon: String
    var count: Int
    var bytes: Int64?    // Real bytes from PHAssetResource. nil until computed.
}

@Observable
@MainActor
final class CleanScanner {
    var categories: [CleanCategory] = []
    var isScanning = false
    var isMeasuring = false
    var measurementProgress: Double = 0
    var authStatus: PHAuthorizationStatus = .notDetermined

    func scan() async {
        isScanning = true
        defer { isScanning = false }

        authStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard authStatus == .authorized || authStatus == .limited else {
            categories = []
            return
        }

        let screenshots = makeCategory(.screenshots, fetch: fetchScreenshots())
        let photos      = makeCategory(.photos,      fetch: fetchPhotos())
        let videos      = makeCategory(.videos,      fetch: fetchVideos())

        categories = [screenshots, photos, videos]

        // Real sizes — heavy, runs in background.
        Task { await measureSizes() }
    }

    // MARK: - Fetches

    private func fetchScreenshots() -> PHFetchResult<PHAsset> {
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        return PHAsset.fetchAssets(with: .image, options: opts)
    }
    private func fetchPhotos() -> PHFetchResult<PHAsset> {
        PHAsset.fetchAssets(with: .image, options: nil)
    }
    private func fetchVideos() -> PHFetchResult<PHAsset> {
        PHAsset.fetchAssets(with: .video, options: nil)
    }

    private func makeCategory(_ kind: CleanCategory.Kind, fetch result: PHFetchResult<PHAsset>) -> CleanCategory {
        switch kind {
        case .screenshots:
            return CleanCategory(kind: .screenshots, title: String(localized: "Screenshots"),
                                 icon: "camera.viewfinder", count: result.count, bytes: nil)
        case .photos:
            return CleanCategory(kind: .photos, title: String(localized: "Photos"),
                                 icon: "photo.stack", count: result.count, bytes: nil)
        case .videos:
            return CleanCategory(kind: .videos, title: String(localized: "Videos"),
                                 icon: "video", count: result.count, bytes: nil)
        }
    }

    // MARK: - Size measurement

    /// Computes real bytes for each category via `PHAssetResource`. Runs sequentially
    /// off the main actor so the UI stays responsive on large libraries.
    private func measureSizes() async {
        isMeasuring = true
        measurementProgress = 0
        defer {
            isMeasuring = false
            measurementProgress = 0
        }

        let snapshot = categories
        let totalSteps = snapshot.count
        guard totalSteps > 0 else { return }

        for (i, cat) in snapshot.enumerated() {
            let bytes = await Task.detached(priority: .utility) {
                Self.computeBytes(for: cat.kind)
            }.value

            if let idx = categories.firstIndex(where: { $0.kind == cat.kind }) {
                categories[idx].bytes = bytes
            }
            measurementProgress = Double(i + 1) / Double(totalSteps)
        }
    }

    nonisolated private static func computeBytes(for kind: CleanCategory.Kind) -> Int64 {
        let fetch: PHFetchResult<PHAsset> = {
            switch kind {
            case .screenshots:
                let opts = PHFetchOptions()
                opts.predicate = NSPredicate(
                    format: "(mediaSubtypes & %d) != 0",
                    PHAssetMediaSubtype.photoScreenshot.rawValue
                )
                return PHAsset.fetchAssets(with: .image, options: opts)
            case .photos:
                return PHAsset.fetchAssets(with: .image, options: nil)
            case .videos:
                return PHAsset.fetchAssets(with: .video, options: nil)
            }
        }()

        var total: Int64 = 0
        fetch.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            for r in resources {
                if let n = r.value(forKey: "fileSize") as? NSNumber {
                    total += n.int64Value
                }
            }
        }
        return total
    }
}
