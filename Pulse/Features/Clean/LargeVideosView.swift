import SwiftUI
import Photos

struct LargeVideosView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var finder = LargeVideoFinder()
    @State private var selection: Set<String> = []
    @State private var deleting = false
    @State private var resultBytes: Int64?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                header
                if finder.isScanning {
                    ProgressView().tint(PulseColor.blue500).frame(maxWidth: .infinity).padding(.vertical, PulseSpace.xxxl)
                } else if finder.videos.isEmpty {
                    emptyState
                } else {
                    summary
                    list
                }
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, 120)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("Large videos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .overlay(alignment: .bottom) { if !selection.isEmpty { deleteBar } }
        .task { if finder.videos.isEmpty { await finder.scan() } }
        .alert("Deleted", isPresented: .init(
            get: { resultBytes != nil },
            set: { _ in resultBytes = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let b = resultBytes {
                Text("Freed \(ByteCountFormatter.string(fromByteCount: b, countStyle: .file)).")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Largest videos")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Sorted by real file size. Videos are usually the biggest space-eaters.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: PulseSpace.m) {
            Image(systemName: "film")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.blue500)
            Text("No videos found")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulseSpace.xxxl)
    }

    private var summary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(finder.videos.count) videos")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
                Text(ByteCountFormatter.string(fromByteCount: finder.totalBytes, countStyle: .file))
                    .font(PulseFont.titleM)
                    .foregroundStyle(PulseColor.textPrimary)
            }
            Spacer()
        }
        .pulseCard()
    }

    private var list: some View {
        VStack(spacing: PulseSpace.s) {
            ForEach(finder.videos) { v in
                row(v)
            }
        }
    }

    private func row(_ v: VideoEntry) -> some View {
        let selected = selection.contains(v.id)
        return Button {
            Haptics.tap(0.3)
            if selected { selection.remove(v.id) } else { selection.insert(v.id) }
        } label: {
            HStack(spacing: PulseSpace.m) {
                VideoThumbnail(asset: v.asset)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(ByteCountFormatter.string(fromByteCount: v.bytes, countStyle: .file))
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                        .monospacedDigit()
                    Text(durationLabel(v.duration))
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? PulseColor.blue500 : PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.card)
    }

    private func durationLabel(_ t: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .positional
        f.zeroFormattingBehavior = .pad
        return f.string(from: t) ?? "—"
    }

    private var deleteBar: some View {
        HStack(spacing: PulseSpace.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selection.count) selected")
                    .font(PulseFont.callout)
                    .foregroundStyle(.white)
                Text(selectedBytesLabel)
                    .font(PulseFont.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Button {
                Task { await doDelete() }
            } label: {
                Text(deleting ? String(localized: "Deleting…") : String(localized: "Delete"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, PulseSpace.xl)
                    .padding(.vertical, PulseSpace.m)
                    .background(Capsule().fill(PulseColor.critical))
            }
            .buttonStyle(.plain)
            .disabled(deleting)
        }
        .padding(PulseSpace.l)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.88)))
        .padding(.horizontal, PulseSpace.l)
        .padding(.bottom, PulseSpace.l)
    }

    private var selectedBytesLabel: String {
        let total = finder.videos.filter { selection.contains($0.id) }.reduce(into: Int64(0)) { $0 += $1.bytes }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    private func doDelete() async {
        let toDelete = finder.videos.filter { selection.contains($0.id) }.map(\.asset)
        guard !toDelete.isEmpty else { return }
        deleting = true
        let result = await PhotoCleaner.delete(toDelete)
        deleting = false
        if result.success {
            resultBytes = result.freed
            finder.consume(selection)
            selection.removeAll()
        }
    }
}

private struct VideoThumbnail: View {
    var asset: PHAsset
    @State private var image: UIImage?
    private let mgr = PHCachingImageManager()
    var body: some View {
        ZStack {
            Color.black
            if let img = image {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
            }
            Image(systemName: "play.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(4)
                .background(Circle().fill(.black.opacity(0.5)))
        }
        .task {
            guard image == nil else { return }
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .opportunistic
            opts.resizeMode = .fast
            mgr.requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: opts
            ) { img, _ in image = img }
        }
    }
}
