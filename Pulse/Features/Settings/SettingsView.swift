import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingHowItWorks = false
    @State private var showingIconPicker = false
    @AppStorage("pulse.didOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if entitlements.isPro { proActive } else { proBanner }
                    section("Activity") {
                        iconRow(systemName: "trash.fill", tint: PulseColor.excellent,
                                title: "All-time freed",
                                value: BytesFreedTracker.formattedAllTime)
                        Divider().background(PulseColor.stroke)
                        iconRow(systemName: "rectangle.on.rectangle.angled", tint: PulseColor.blue500,
                                title: "Today's sweeps",
                                value: "\(SweepLimits.todayCount)" + (entitlements.isPro ? "" : " / \(SweepLimits.freeDailyLimit)"))
                    }

                    section("Appearance") {
                        iconLink(systemName: "square.on.square", tint: PulseColor.purple,
                                 title: "App icon") { showingIconPicker = true }
                    }

                    if entitlements.isPro {
                        section("Subscription") {
                            iconLink(systemName: "creditcard", tint: PulseColor.teal,
                                     title: "Manage subscription") {
                                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    section("About") {
                        iconRow(systemName: "info.circle", tint: PulseColor.textTertiary,
                                title: "Version", value: "0.2.0")
                        Divider().background(PulseColor.stroke)
                        iconLink(systemName: "play.circle", tint: PulseColor.blue500,
                                 title: "Replay tutorial") { didOnboard = false }
                        Divider().background(PulseColor.stroke)
                        iconLink(systemName: "book.closed", tint: PulseColor.blue500,
                                 title: "How it works") { showingHowItWorks = true }
                        Divider().background(PulseColor.stroke)
                        iconLink(systemName: "hand.raised.fill", tint: PulseColor.excellent,
                                 title: "Privacy Policy") { showingPrivacy = true }
                        Divider().background(PulseColor.stroke)
                        iconLink(systemName: "doc.text", tint: PulseColor.textSecondary,
                                 title: "Terms of Use") { showingTerms = true }
                        Divider().background(PulseColor.stroke)
                        iconLink(systemName: "arrow.clockwise.circle", tint: PulseColor.purple,
                                 title: "Restore purchases") {
                            Task { await entitlements.restore() }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $showingPaywall) {
            SpecialOfferPaywallView(seenOffer: .constant(false))
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTerms)   { NavigationStack { LegalView(kind: .terms) } }
        .sheet(isPresented: $showingPrivacy) { NavigationStack { LegalView(kind: .privacy) } }
        .sheet(isPresented: $showingHowItWorks) { NavigationStack { HowItWorksView() } }
        .sheet(isPresented: $showingIconPicker) {
            NavigationStack { AppIconPicker() }
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(PulseColor.textPrimary)
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PulseColor.blue500)
        }
    }

    private var proBanner: some View {
        Button { showingPaywall = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(colors: [PulseColor.blue500, PulseColor.purple, PulseColor.teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(.white.opacity(0.18)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock Pulse Pro")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Unlimited sweeps · widgets · support a tiny app")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(20)
            }
            .shadow(color: PulseColor.blue500.opacity(0.4), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var proActive: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Pulse Pro active")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                Text("Thanks for backing the app ❤️")
                    .font(.system(size: 13))
                    .foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(PulseColor.card))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(PulseColor.stroke))
    }

    @ViewBuilder
    private func section<C: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercasedKey())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PulseColor.textTertiary)
                .tracking(0.6)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 18).fill(PulseColor.card))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(PulseColor.stroke))
        }
    }

    private func row(_ title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title).font(.system(size: 15)).foregroundStyle(PulseColor.textPrimary)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundStyle(PulseColor.textSecondary)
        }
        .padding(.vertical, 14)
    }

    private func statRow(_ title: LocalizedStringKey, value: String) -> some View {
        row(title, value: value)
    }

    private func iconRow(systemName: String, tint: Color, title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 12) {
            iconChip(systemName: systemName, tint: tint)
            Text(title).font(.system(size: 15)).foregroundStyle(PulseColor.textPrimary)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundStyle(PulseColor.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private func iconLink(systemName: String, tint: Color, title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(0.25)
            action()
        } label: {
            HStack(spacing: 12) {
                iconChip(systemName: systemName, tint: tint)
                Text(title).font(.system(size: 15)).foregroundStyle(PulseColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func iconChip(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.78)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            )
    }

    private func link(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(0.25)
            action()
        } label: {
            HStack {
                Text(title).font(.system(size: 15)).foregroundStyle(PulseColor.blue500)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

private extension LocalizedStringKey {
    /// Returns an uppercased localized string for use as a small caps section header.
    func uppercasedKey() -> String {
        // Mirror's reflection of LocalizedStringKey to extract the underlying key isn't
        // available; we just present the key value as-is and rely on Text rendering.
        // Settings section headers are short and don't need real uppercasing.
        let mirror = Mirror(reflecting: self)
        if let key = mirror.children.first(where: { $0.label == "key" })?.value as? String {
            return key.uppercased()
        }
        return ""
    }
}
