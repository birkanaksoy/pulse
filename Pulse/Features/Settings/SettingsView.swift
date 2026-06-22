import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingHowItWorks = false
    @AppStorage("pulse.didOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if entitlements.isPro { proActive } else { proBanner }
                    section("Activity") {
                        statRow("All-time freed", value: BytesFreedTracker.formattedAllTime)
                    }
                    section("About") {
                        row("Version", value: "0.2.0")
                        Divider().background(PulseColor.stroke)
                        link("Replay tutorial") { didOnboard = false }
                        Divider().background(PulseColor.stroke)
                        link("How it works") { showingHowItWorks = true }
                        Divider().background(PulseColor.stroke)
                        link("Privacy Policy") { showingPrivacy = true }
                        Divider().background(PulseColor.stroke)
                        link("Terms of Use") { showingTerms = true }
                        Divider().background(PulseColor.stroke)
                        link("Restore purchases") {
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
