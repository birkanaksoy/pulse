import SwiftUI
import Photos

struct CleanView: View {
    @State private var scanner = CleanScanner()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                if scanner.categories.isEmpty {
                    initialState
                } else {
                    categoryList
                    disclaimer
                }
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.l)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(PulseColor.muted.ignoresSafeArea())
        .task {
            if scanner.categories.isEmpty { await scanner.scan() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Clean")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pulse suggests. You decide.")
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var initialState: some View {
        VStack(spacing: PulseSpace.l) {
            if scanner.isScanning {
                ProgressView().scaleEffect(1.4).tint(PulseColor.blue500)
                Text("Scanning your library…")
                    .font(PulseFont.body)
                    .foregroundStyle(PulseColor.textSecondary)
            } else if scanner.authStatus == .denied || scanner.authStatus == .restricted {
                deniedState
            } else {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulseSpace.xxxl)
    }

    private var deniedState: some View {
        VStack(spacing: PulseSpace.l) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.fair)
            Text("Photo access denied")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pulse needs read access to count photos, videos and screenshots. Enable it in Settings.")
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
            openSystem(for: c)
        } label: {
            HStack(spacing: PulseSpace.l) {
                Image(systemName: c.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PulseColor.blue500)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(PulseColor.blue50))
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
        .buttonStyle(.plain)
    }

    private func subtitle(for c: CleanCategory) -> Text {
        guard c.count > 0 else { return Text("None found") }
        let items = Text("\(c.count) items")
        if let b = c.bytes {
            let size = ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
            return items + Text(" · ") + Text(size)
        }
        return items + Text(" · ") + Text("calculating…").foregroundStyle(PulseColor.textTertiary)
    }

    private var disclaimer: some View {
        Text("Pulse never deletes anything. Each category opens the relevant Apple app or Settings so you stay in control.")
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)
            .padding(.horizontal, PulseSpace.s)
    }

    private func openSystem(for c: CleanCategory) {
        if let u = URL(string: "photos-redirect://"), UIApplication.shared.canOpenURL(u) {
            UIApplication.shared.open(u)
        }
    }
}
