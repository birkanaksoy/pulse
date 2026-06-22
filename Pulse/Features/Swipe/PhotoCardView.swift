import SwiftUI
import Photos
import UIKit

/// Loads and shows a single asset full-bleed, with the video/photo overlay
/// hint if applicable.
struct PhotoCardView: View {
    var asset: PHAsset
    @State private var image: UIImage?
    @State private var size: Int64 = 0
    private let mgr = PHCachingImageManager()

    var body: some View {
        ZStack {
            Color.black

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView().tint(.white).scaleEffect(1.2)
            }

            // Top-left meta chip
            VStack {
                HStack {
                    metaChip
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
        }
        .task { await load() }
    }

    private var metaChip: some View {
        HStack(spacing: 6) {
            Image(systemName: typeIcon)
                .font(.system(size: 12, weight: .semibold))
            Text(typeLabel)
                .font(.system(size: 12, weight: .semibold))
            if size > 0 {
                Text("·").foregroundStyle(.white.opacity(0.5))
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.7), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
    }

    private var typeIcon: String {
        if asset.mediaType == .video { return "video.fill" }
        if asset.mediaSubtypes.contains(.photoLive) { return "livephoto" }
        if asset.mediaSubtypes.contains(.photoScreenshot) { return "camera.viewfinder" }
        if asset.burstIdentifier != nil { return "rectangle.stack.fill" }
        return "photo.fill"
    }

    private var typeLabel: String {
        if asset.mediaType == .video {
            let s = Int(asset.duration.rounded())
            return String(format: "%d:%02d", s / 60, s % 60)
        }
        if asset.mediaSubtypes.contains(.photoLive) { return String(localized: "Live") }
        if asset.mediaSubtypes.contains(.photoScreenshot) { return String(localized: "Screenshot") }
        if asset.burstIdentifier != nil { return String(localized: "Burst") }
        return String(localized: "Photo")
    }

    @MainActor
    private func load() async {
        guard image == nil else { return }
        let target = CGSize(width: 1200, height: 1600)
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .opportunistic
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = false
        mgr.requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: opts) { img, _ in
            if let img { self.image = img }
        }
        size = PhotoCleaner.bytes(of: asset)
    }
}
