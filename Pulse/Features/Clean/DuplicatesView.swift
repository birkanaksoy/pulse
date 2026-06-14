import SwiftUI
import Photos

struct DuplicatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var detector = DuplicateDetector()
    @State private var presentedGroup: DuplicateGroup?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                header
                if detector.isScanning {
                    progressCard
                } else if detector.groups.isEmpty {
                    emptyOrStart
                } else {
                    summary
                    ForEach(detector.groups) { group in
                        groupCard(group)
                    }
                }
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("Duplicates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .sheet(item: $presentedGroup) { g in
            NavigationStack {
                PhotoGridView(
                    assets: g.assets,
                    preselectedSkipFirst: true,
                    title: "Duplicate group",
                    onDelete: { _ in detector.consume(g) }
                )
            }
            .pulseSheet()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Duplicate photos")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Visually similar images grouped together. The first photo of each group is suggested to keep.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var progressCard: some View {
        VStack(spacing: PulseSpace.m) {
            ProgressView(value: detector.progress)
                .progressViewStyle(.linear)
                .tint(PulseColor.blue500)
            Text("\(Int(detector.progress * 100))% scanned")
                .font(PulseFont.callout.monospacedDigit())
                .foregroundStyle(PulseColor.textSecondary)
        }
        .pulseCard()
    }

    private var emptyOrStart: some View {
        VStack(spacing: PulseSpace.m) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.blue500)
            Text("Find duplicates")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pulse scans your library on-device with perceptual hashing. Nothing is uploaded.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Scan now", systemImage: "arrow.right") {
                Task { await detector.scan() }
            }
            .padding(.top, PulseSpace.s)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulseSpace.xxxl)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Potential savings")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: detector.totalSavings, countStyle: .file))
                    .font(PulseFont.titleM)
                    .foregroundStyle(PulseColor.blue500)
            }
            Text("\(detector.groups.count) groups · \(detector.groups.reduce(0) { $0 + $1.assets.count - 1 }) extras")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
        }
        .pulseCard()
    }

    private func groupCard(_ g: DuplicateGroup) -> some View {
        Button { presentedGroup = g } label: {
            HStack(spacing: PulseSpace.m) {
                ThumbnailStripe(assets: Array(g.assets.prefix(4)))
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(g.assets.count) similar")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Save \(ByteCountFormatter.string(fromByteCount: g.savings, countStyle: .file))")
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.card)
    }
}

private struct ThumbnailStripe: View {
    var assets: [PHAsset]
    @State private var image: UIImage?
    private let mgr = PHCachingImageManager()

    var body: some View {
        ZStack {
            Color.gray.opacity(0.15)
            if let img = image {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
            }
        }
        .task {
            guard let first = assets.first, image == nil else { return }
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .opportunistic
            opts.resizeMode = .fast
            mgr.requestImage(
                for: first,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: opts
            ) { img, _ in
                image = img
            }
        }
    }
}
