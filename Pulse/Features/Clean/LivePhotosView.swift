import SwiftUI
import Photos

struct LivePhotosView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var converter = LivePhotoConverter()
    @State private var selection: Set<String> = []
    @State private var resultBytes: Int64?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                header
                if converter.isScanning {
                    ProgressView().tint(PulseColor.blue500).frame(maxWidth: .infinity).padding(.vertical, PulseSpace.xxxl)
                } else if converter.entries.isEmpty {
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
        .navigationTitle("Live Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .overlay(alignment: .bottom) { if !selection.isEmpty { convertBar } }
        .task { if converter.entries.isEmpty { await converter.scan() } }
        .alert("Converted", isPresented: .init(
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
            Text("Live Photos")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Each Live Photo carries a 1.5s video. Convert to still and save ~60% of the size — photo stays in your library.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: PulseSpace.m) {
            Image(systemName: "livephoto")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.blue500)
            Text("No Live Photos")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulseSpace.xxxl)
    }

    private var summary: some View {
        HStack {
            Text("Potential savings").font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: converter.totalSavings, countStyle: .file))
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.blue500)
        }
        .pulseCard()
    }

    private var list: some View {
        VStack(spacing: PulseSpace.s) {
            ForEach(converter.entries) { e in
                row(e)
            }
        }
    }

    private func row(_ e: LivePhotoEntry) -> some View {
        let selected = selection.contains(e.id)
        return Button {
            Haptics.tap(0.3)
            if selected { selection.remove(e.id) } else { selection.insert(e.id) }
        } label: {
            HStack(spacing: PulseSpace.m) {
                LivePhotoThumb(asset: e.asset)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save \(ByteCountFormatter.string(fromByteCount: e.savings, countStyle: .file))")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("\(ByteCountFormatter.string(fromByteCount: e.bytes, countStyle: .file)) → \(ByteCountFormatter.string(fromByteCount: e.bytesAfter, countStyle: .file))")
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

    private var convertBar: some View {
        HStack(spacing: PulseSpace.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selection.count) Live Photos")
                    .font(PulseFont.callout)
                    .foregroundStyle(.white)
                Text(selectedSavingsLabel)
                    .font(PulseFont.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Button {
                Task { await doConvert() }
            } label: {
                Text(converter.isConverting ? String(localized: "Converting…") : String(localized: "Convert"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, PulseSpace.xl)
                    .padding(.vertical, PulseSpace.m)
                    .background(Capsule().fill(PulseColor.blue500))
            }
            .buttonStyle(.plain)
            .disabled(converter.isConverting)
        }
        .padding(PulseSpace.l)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.88)))
        .padding(.horizontal, PulseSpace.l)
        .padding(.bottom, PulseSpace.l)
    }

    private var selectedSavingsLabel: String {
        let total = converter.entries.filter { selection.contains($0.id) }.reduce(into: Int64(0)) { $0 += $1.savings }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    private func doConvert() async {
        let toConvert = converter.entries.filter { selection.contains($0.id) }
        guard !toConvert.isEmpty else { return }
        let freed = await converter.convert(toConvert)
        resultBytes = freed
        selection.removeAll()
    }
}

private struct LivePhotoThumb: View {
    var asset: PHAsset
    @State private var image: UIImage?
    private let mgr = PHCachingImageManager()
    var body: some View {
        ZStack {
            Color.gray.opacity(0.15)
            if let img = image {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
            }
            Image(systemName: "livephoto")
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
