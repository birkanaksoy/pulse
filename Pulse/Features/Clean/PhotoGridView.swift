import SwiftUI
import Photos

struct PhotoGridView: View {
    var assets: [PHAsset]
    var preselectedSkipFirst: Bool = false
    var title: LocalizedStringKey

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<String> = []
    @State private var deleting = false
    @State private var resultBytes: Int64?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    private let mgr = PHCachingImageManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.m) {
                header
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        cell(asset)
                    }
                }
            }
            .padding(.bottom, 120)
        }
        .background(PulseColor.canvas.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(allSelected ? "None" : "All") {
                    Haptics.tap()
                    if allSelected { selection.removeAll() }
                    else { selection = Set(assets.map { $0.localIdentifier }) }
                }
            }
        }
        .overlay(alignment: .bottom) { deleteBar }
        .onAppear(perform: preselect)
        .alert("Deleted", isPresented: .init(
            get: { resultBytes != nil },
            set: { _ in resultBytes = nil }
        )) {
            Button("OK", role: .cancel) {
                if assets.allSatisfy({ selection.contains($0.localIdentifier) }) {
                    dismiss()
                }
            }
        } message: {
            if let b = resultBytes {
                Text("Freed \(ByteCountFormatter.string(fromByteCount: b, countStyle: .file)).")
            }
        }
    }

    private var allSelected: Bool {
        !assets.isEmpty && assets.allSatisfy { selection.contains($0.localIdentifier) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(selection.count) of \(assets.count) selected")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
            Text("Tap to toggle. iOS asks you to confirm before anything is deleted.")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
        }
        .padding(.horizontal, PulseSpace.l)
    }

    @ViewBuilder
    private func cell(_ asset: PHAsset) -> some View {
        let isSelected = selection.contains(asset.localIdentifier)
        Button {
            Haptics.tap(0.3)
            if isSelected { selection.remove(asset.localIdentifier) }
            else { selection.insert(asset.localIdentifier) }
        } label: {
            ThumbnailView(asset: asset, mgr: mgr)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.85))
                        .background(
                            Circle().fill(isSelected ? PulseColor.blue500 : Color.black.opacity(0.35))
                                .frame(width: 22, height: 22)
                        )
                        .padding(6)
                }
                .overlay(
                    Rectangle().strokeBorder(
                        isSelected ? PulseColor.blue500 : .clear,
                        lineWidth: 2
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private var deleteBar: some View {
        HStack(spacing: PulseSpace.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selection.count) selected")
                    .font(PulseFont.callout)
                    .foregroundStyle(.white)
                Text("Tap delete to confirm.")
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
            .disabled(selection.isEmpty || deleting)
            .opacity(selection.isEmpty ? 0.5 : 1)
        }
        .padding(PulseSpace.l)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.88))
        )
        .padding(.horizontal, PulseSpace.l)
        .padding(.bottom, PulseSpace.l)
    }

    private func preselect() {
        guard preselectedSkipFirst, assets.count > 1 else { return }
        selection = Set(assets.dropFirst().map { $0.localIdentifier })
    }

    private func doDelete() async {
        let toDelete = assets.filter { selection.contains($0.localIdentifier) }
        guard !toDelete.isEmpty else { return }
        deleting = true
        let result = await PhotoCleaner.delete(toDelete)
        deleting = false
        if result.success {
            resultBytes = result.freed
            selection.removeAll()
        }
    }
}

private struct ThumbnailView: View {
    var asset: PHAsset
    var mgr: PHCachingImageManager
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.gray.opacity(0.15)
            if let img = image {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
            }
        }
        .task {
            guard image == nil else { return }
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .opportunistic
            opts.resizeMode = .fast
            mgr.requestImage(
                for: asset,
                targetSize: CGSize(width: 220, height: 220),
                contentMode: .aspectFill,
                options: opts
            ) { img, _ in
                image = img
            }
        }
    }
}
