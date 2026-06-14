import SwiftUI
import Photos

struct CleanView: View {
    var scanner: CleanScanner
    @State private var presentedCategory: CleanCategory.Kind?
    @State private var showingDuplicates = false
    @State private var showingBursts = false
    @State private var showingLargeVideos = false
    @State private var showingLivePhotos = false

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            ScrollView {
                VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                    header
                    if scanner.isScanning {
                        ProgressView().scaleEffect(1.4).tint(PulseColor.blue500)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PulseSpace.xxxl)
                    } else if scanner.authStatus == .denied || scanner.authStatus == .restricted {
                        deniedState
                    } else if scanner.categories.isEmpty {
                        notStartedState
                    } else {
                        bytesFreedBanner
                        smartCleaners
                        categoryList
                        recentlyDeletedNudge
                        disclaimer
                    }
                }
                .padding(.horizontal, PulseSpace.xl)
                .padding(.top, PulseSpace.l)
                .padding(.bottom, PulseSpace.xxxl)
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(item: $presentedCategory) { kind in
            NavigationStack { CleanCategoryDetail(kind: kind) }
                .pulseSheet()
        }
        .sheet(isPresented: $showingDuplicates) {
            NavigationStack { DuplicatesView() }.pulseSheet()
        }
        .sheet(isPresented: $showingBursts) {
            NavigationStack { BurstsView() }.pulseSheet()
        }
        .sheet(isPresented: $showingLargeVideos) {
            NavigationStack { LargeVideosView() }.pulseSheet()
        }
        .sheet(isPresented: $showingLivePhotos) {
            NavigationStack { LivePhotosView() }.pulseSheet()
        }
        .task {
            if scanner.categories.isEmpty { await scanner.scan() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await scanner.scan() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Clean")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Real deletion, real bytes freed. iOS confirms every batch.")
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var bytesFreedBanner: some View {
        Group {
            if BytesFreedTracker.allTime > 0 {
                HStack(spacing: PulseSpace.m) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient(colors: [PulseColor.excellent, PulseColor.blue500],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Freed all-time")
                            .font(PulseFont.callout)
                            .foregroundStyle(PulseColor.textSecondary)
                        Text(BytesFreedTracker.formattedAllTime)
                            .font(PulseFont.titleM)
                            .foregroundStyle(PulseColor.textPrimary)
                    }
                    Spacer()
                }
                .pulseCard()
            }
        }
    }

    private var smartCleaners: some View {
        VStack(alignment: .leading, spacing: PulseSpace.s) {
            SectionHeader("Smart cleaners")
            VStack(spacing: PulseSpace.m) {
                cleanerCard(
                    icon: "rectangle.stack.badge.minus",
                    title: String(localized: "Find duplicate photos"),
                    subtitle: String(localized: "Visual fingerprinting, on-device. No upload.")
                ) { showingDuplicates = true }
                cleanerCard(
                    icon: "camera.aperture",
                    title: String(localized: "Burst photos"),
                    subtitle: String(localized: "Keep the best of every burst, drop the rest.")
                ) { showingBursts = true }
                cleanerCard(
                    icon: "film",
                    title: String(localized: "Largest videos"),
                    subtitle: String(localized: "Sorted by real file size — usually the biggest win.")
                ) { showingLargeVideos = true }
                cleanerCard(
                    icon: "livephoto",
                    title: String(localized: "Live Photos → still"),
                    subtitle: String(localized: "Convert to still, save ~60% per photo.")
                ) { showingLivePhotos = true }
            }
        }
    }

    private func cleanerCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text(subtitle)
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

    private var recentlyDeletedNudge: some View {
        Button {
            Haptics.tap()
            if let u = URL(string: "photos-redirect://"), UIApplication.shared.canOpenURL(u) {
                UIApplication.shared.open(u)
            }
        } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "trash")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PulseColor.critical)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(PulseColor.critical.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Empty Recently Deleted")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("iOS keeps deleted photos for 30 days. Empty now to reclaim space instantly.")
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.card)
    }

    private var duplicateCard: some View {
        Button { showingDuplicates = true } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "rectangle.stack.badge.minus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Find duplicate photos")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Visual fingerprinting, on-device. No upload.")
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

    private var categoryList: some View {
        VStack(spacing: PulseSpace.m) {
            if scanner.isMeasuring {
                measuringBanner
            }
            ForEach(scanner.categories) { c in
                categoryRow(c)
            }
        }
    }

    private var measuringBanner: some View {
        HStack(spacing: PulseSpace.m) {
            ProgressView(value: scanner.measurementProgress)
                .progressViewStyle(.linear)
                .tint(PulseColor.blue500)
            Text("\(Int(scanner.measurementProgress * 100))%")
                .font(PulseFont.footnote.monospacedDigit())
                .foregroundStyle(PulseColor.textTertiary)
        }
        .padding(.horizontal, PulseSpace.l)
        .padding(.vertical, PulseSpace.m)
        .background(PulseColor.card, in: RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                .strokeBorder(PulseColor.stroke, lineWidth: 1)
        )
    }

    private func categoryRow(_ c: CleanCategory) -> some View {
        Button {
            Haptics.tap()
            presentedCategory = c.kind
        } label: {
            HStack(spacing: PulseSpace.l) {
                Image(systemName: c.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.title)
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    subtitle(for: c)
                        .font(PulseFont.callout)
                        .foregroundStyle(c.count > 0 ? PulseColor.textSecondary : PulseColor.textTertiary)
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

    private func subtitle(for c: CleanCategory) -> Text {
        guard c.count > 0 else { return Text("None found") }
        let items = Text("\(c.count) items")
        if let b = c.bytes {
            let size = ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
            return items + Text(" · ") + Text(size)
        }
        return items + Text(" · ") + Text("calculating…")
    }

    private var disclaimer: some View {
        Text("Pulse opens the system delete dialog for every batch. Nothing is deleted without your tap.")
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)
            .padding(.horizontal, PulseSpace.s)
    }

    // MARK: - Empty states

    private var deniedState: some View {
        VStack(spacing: PulseSpace.l) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.fair)
            Text("Photo access denied")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pulse needs read+write access to actually clean. Enable it in Settings.")
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulseSpace.xl)
            PrimaryButton(title: "Open Settings", systemImage: "arrow.up.right") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding(.vertical, PulseSpace.xxxl)
    }

    private var notStartedState: some View {
        VStack(spacing: PulseSpace.l) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.blue500)
            Text("Photo access required")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            PrimaryButton(title: "Allow & Scan", systemImage: "checkmark") {
                Task { await scanner.scan() }
            }
        }
        .padding(.vertical, PulseSpace.xxxl)
    }
}

// MARK: - Sheet wrapper

extension CleanCategory.Kind: Identifiable {
    public var id: String { rawValue }
}

private struct CleanCategoryDetail: View {
    var kind: CleanCategory.Kind
    @State private var assets: [PHAsset] = []

    var body: some View {
        Group {
            if assets.isEmpty {
                ProgressView().tint(PulseColor.blue500)
            } else {
                PhotoGridView(assets: assets, title: title)
            }
        }
        .task { await load() }
    }

    private var title: LocalizedStringKey {
        switch kind {
        case .screenshots: return "Screenshots"
        case .photos:      return "Photos"
        case .videos:      return "Videos"
        }
    }

    @MainActor
    private func load() async {
        let assets: [PHAsset] = await Task.detached(priority: .userInitiated) {
            var out: [PHAsset] = []
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
            fetch.enumerateObjects { a, _, _ in out.append(a) }
            return out
        }.value
        self.assets = assets
    }
}
