import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .annual

    enum Plan: String, CaseIterable {
        case annual, monthly
        var productID: String {
            self == .annual ? "com.birkan.pulse.pro.annual" : "com.birkan.pulse.pro.monthly"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PulseSpace.xxl) {
                heroRing
                title
                bullets
                planSelector
                ctaButton
                legalDisclaimer
                footnoteRow
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.xxl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(PulseColor.canvas.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PulseColor.textTertiary)
                    .padding(10)
                    .background(Circle().fill(PulseColor.muted))
            }
            .padding(PulseSpace.l)
        }
        .sheet(isPresented: $showingTerms) {
            NavigationStack { LegalView(kind: .terms) }.pulseSheet()
        }
        .sheet(isPresented: $showingPrivacy) {
            NavigationStack { LegalView(kind: .privacy) }.pulseSheet()
        }
    }

    private var heroRing: some View {
        PulseRing(score: 100, size: 180)
    }

    private var title: some View {
        VStack(spacing: PulseSpace.s) {
            Text("Unlock Pulse Pro")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Deeper diagnostics. Honest data.")
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            bullet("calendar", "Weekly health reports")
            bullet("battery.100.bolt", "Battery diagnostics")
            bullet("chart.xyaxis.line", "Full scan history")
            bullet("rectangle.stack.badge.plus", "Home & Lock Screen widgets")
            bullet("app.badge", "3 alternate app icons")
            bullet("heart.text.square", "Support a tiny, honest app")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCard()
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(spacing: PulseSpace.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PulseColor.blue500)
                .frame(width: 24)
            Text(text)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textPrimary)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PulseColor.excellent)
        }
    }

    private var planSelector: some View {
        VStack(spacing: PulseSpace.m) {
            planRow(.annual, title: "Annual", price: priceString(for: .annual) ?? "$29.99/yr", badge: "Save 58%")
            planRow(.monthly, title: "Monthly", price: priceString(for: .monthly) ?? "$5.99/mo", badge: nil)
        }
    }

    private func planRow(_ plan: Plan, title: String, price: String, badge: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            Haptics.tap()
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: PulseSpace.s) {
                        Text(title).font(PulseFont.titleM).foregroundStyle(PulseColor.textPrimary)
                        if let b = badge {
                            Text(b)
                                .font(PulseFont.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(PulseColor.blue500))
                        }
                    }
                    Text(price).font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? PulseColor.blue500 : PulseColor.textTertiary)
            }
            .padding(PulseSpace.l)
            .background(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .fill(PulseColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .strokeBorder(selected ? PulseColor.blue500 : PulseColor.stroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var ctaButton: some View {
        VStack(spacing: PulseSpace.s) {
            PrimaryButton(
                title: "Start Free Trial",
                systemImage: "arrow.right",
                isLoading: entitlements.purchaseInFlight
            ) {
                Task { await tryPurchase() }
            }
            Text("7 days free, then \(priceString(for: selectedPlan) ?? "—"). Cancel anytime.")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var legalDisclaimer: some View {
        Text("Subscriptions auto-renew at the end of each billing period unless cancelled at least 24 hours before. Manage or cancel anytime in your App Store account. Payment is charged to your Apple ID. By continuing you agree to the Terms and Privacy Policy below.")
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, PulseSpace.m)
    }

    @State private var showingTerms = false
    @State private var showingPrivacy = false

    private var footnoteRow: some View {
        HStack(spacing: PulseSpace.xl) {
            Button("Restore") { Task { await entitlements.restore(); maybeDismiss() } }
            Button("Terms") { showingTerms = true }
            Button("Privacy") { showingPrivacy = true }
        }
        .font(PulseFont.footnote)
        .foregroundStyle(PulseColor.textTertiary)
    }

    private func priceString(for plan: Plan) -> String? {
        entitlements.products.first { $0.id == plan.productID }?.displayPrice
    }

    private func tryPurchase() async {
        guard let product = entitlements.products.first(where: { $0.id == selectedPlan.productID }) else {
            // Dev fallback when products aren't configured yet.
            entitlements.devTogglePro()
            maybeDismiss()
            return
        }
        await entitlements.purchase(product)
        maybeDismiss()
    }

    private func maybeDismiss() {
        if entitlements.isPro { dismiss() }
    }
}
