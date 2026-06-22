import SwiftUI
import StoreKit

/// Shown once, right after onboarding. Walks the user through a brief
/// "preparing your best offer" animation, then presents 3 plans:
/// Weekly · Monthly · Lifetime.
struct SpecialOfferPaywallView: View {
    @Binding var seenOffer: Bool
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: Phase = .preparing
    @State private var selectedPlan: Plan = .lifetime
    @State private var prepareProgress: Double = 0
    @State private var prepareStage: String = ""
    @State private var canSkip = false
    @State private var closeButtonVisible = false

    /// Seconds before the "No thanks" text link fades in.
    private let skipDelay: TimeInterval = 3.0
    /// Seconds before the small X close button appears (Apple still requires
    /// an obvious dismissal — we keep it short so we're compliant).
    private let closeButtonDelay: TimeInterval = 1.5

    enum Phase { case preparing, offering }

    enum Plan: String, CaseIterable, Identifiable {
        case weekly, monthly, lifetime
        var id: String { rawValue }
        var productID: String {
            switch self {
            case .weekly:   return "com.birkan.pulse.pro.weekly"
            case .monthly:  return "com.birkan.pulse.pro.monthly"
            case .lifetime: return "com.birkan.pulse.lifetime"
            }
        }
        var fallbackPrice: String {
            switch self {
            case .weekly:   return "$1.99"
            case .monthly:  return "$3.99"
            case .lifetime: return "$19.99"
            }
        }
        var period: LocalizedStringKey {
            switch self {
            case .weekly:   return "/week"
            case .monthly:  return "/month"
            case .lifetime: return "one-time"
            }
        }
        var displayName: LocalizedStringKey {
            switch self {
            case .weekly:   return "Weekly"
            case .monthly:  return "Monthly"
            case .lifetime: return "Lifetime"
            }
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.purple)
            Group {
                switch phase {
                case .preparing: preparingView
                case .offering:  offeringView
                }
            }
        }
        .task { await runPreparing() }
    }

    // MARK: - Preparing

    private var preparingView: some View {
        VStack(spacing: PulseSpace.xl) {
            Spacer()
            ZStack {
                Circle().stroke(PulseColor.stroke, lineWidth: 12).frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: prepareProgress)
                    .stroke(
                        LinearGradient(colors: [PulseColor.blue500, PulseColor.purple, PulseColor.teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 0.5), value: prepareProgress)
                PulseLogo(size: 120, shadow: true)
            }
            VStack(spacing: 6) {
                Text("Preparing your best offer")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text(prepareStage)
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PulseSpace.xxl)
                    .animation(.easeInOut, value: prepareStage)
            }
            Spacer()
        }
    }

    @MainActor
    private func runPreparing() async {
        guard phase == .preparing else { return }
        let stages: [(String, Double)] = [
            (String(localized: "Reading your phone profile…"), 0.25),
            (String(localized: "Tailoring features to your needs…"), 0.55),
            (String(localized: "Finding your best price…"), 0.85),
            (String(localized: "Almost ready…"), 1.0)
        ]
        prepareStage = stages.first?.0 ?? ""
        for (text, target) in stages {
            prepareStage = text
            prepareProgress = target
            try? await Task.sleep(nanoseconds: 800_000_000)
        }
        withAnimation(.smooth(duration: 0.6)) { phase = .offering }
    }

    // MARK: - Offering

    private var offeringView: some View {
        ScrollView {
            VStack(spacing: PulseSpace.xxl) {
                header
                bullets
                planSelector
                ctaButton
                legalRow
                Spacer().frame(height: PulseSpace.l)
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .task { await runSkipTimers() }
    }

    @MainActor
    private func runSkipTimers() async {
        // Close button — Apple requires reasonably discoverable dismissal.
        try? await Task.sleep(nanoseconds: UInt64(closeButtonDelay * 1_000_000_000))
        withAnimation(.easeIn(duration: 0.5)) { closeButtonVisible = true }
        // 'No thanks' text link — appears later, subtler.
        let remaining = skipDelay - closeButtonDelay
        try? await Task.sleep(nanoseconds: UInt64(max(0, remaining) * 1_000_000_000))
        withAnimation(.easeIn(duration: 0.5)) { canSkip = true }
    }

    private var header: some View {
        VStack(spacing: PulseSpace.s) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.callout)
                Text("Just for you")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [PulseColor.blue500, PulseColor.purple],
                                   startPoint: .leading, endPoint: .trailing)
                )
            )

            Text("Unlock Pulse Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(PulseColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(headlineCopy)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulseSpace.l)
        }
        .padding(.top, PulseSpace.xxl)
    }

    private var headlineCopy: LocalizedStringKey {
        "Real cleaning. Honest diagnostics. No fake metrics."
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            bullet("wand.and.stars",        "One-tap Magic Cleanup")
            bullet("rectangle.stack.badge.minus", "Unlimited duplicate scans")
            bullet("waveform",              "Pro insights & thermal heatmap")
            bullet("chart.xyaxis.line",     "Full scan history")
            bullet("rectangle.stack.badge.plus", "Widgets + Watch complication")
            bullet("app.badge",             "3 alternate app icons")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCard()
    }

    private func bullet(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: PulseSpace.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PulseColor.blue500)
                .frame(width: 28)
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
            planRow(.weekly,   badge: nil)
            planRow(.monthly,  badge: nil)
            planRow(.lifetime, badge: String(localized: "Best value"))
        }
    }

    private func planRow(_ plan: Plan, badge: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            Haptics.tap()
            selectedPlan = plan
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(plan.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(PulseColor.textPrimary)
                        if let b = badge {
                            Text(b)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                                )
                        }
                    }
                    HStack(spacing: 4) {
                        Text(priceString(for: plan))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PulseColor.textSecondary)
                        Text(plan.period)
                            .font(.system(size: 13))
                            .foregroundStyle(PulseColor.textTertiary)
                    }
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(selected ? PulseColor.blue500 : PulseColor.textTertiary)
            }
            .padding(PulseSpace.l)
            .background(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .fill(selected ? AnyShapeStyle(PulseColor.blue500.opacity(0.08)) : AnyShapeStyle(PulseColor.card))
            )
            .overlay(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .strokeBorder(selected ? PulseColor.blue500 : PulseColor.stroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func priceString(for plan: Plan) -> String {
        entitlements.products.first { $0.id == plan.productID }?.displayPrice ?? plan.fallbackPrice
    }

    private var ctaButton: some View {
        VStack(spacing: PulseSpace.s) {
            PrimaryButton(
                title: selectedPlan == .lifetime ? "Buy Lifetime" : "Continue",
                systemImage: "arrow.right",
                isLoading: entitlements.purchaseInFlight
            ) {
                Task { await tryPurchase() }
            }
            Text("\(priceString(for: selectedPlan))\(periodLabel)")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var periodLabel: String {
        switch selectedPlan {
        case .weekly:   return "/" + String(localized: "week")
        case .monthly:  return "/" + String(localized: "month")
        case .lifetime: return " " + String(localized: "one-time")
        }
    }

    private var legalRow: some View {
        VStack(spacing: 12) {
            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the period. Manage anytime in your App Store account.")
                .font(.system(size: 11))
                .foregroundStyle(PulseColor.textTertiary)
                .multilineTextAlignment(.center)

            Button("Restore") {
                Task { await entitlements.restore(); finishIfPro() }
            }
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)

            // Delayed-skip text link — invisible until skipDelay elapses.
            Button {
                Haptics.tap(0.2)
                finish()
            } label: {
                Text("No thanks, continue with limited features")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(PulseColor.textTertiary.opacity(0.7))
                    .underline()
            }
            .buttonStyle(.plain)
            .opacity(canSkip ? 1 : 0)
            .disabled(!canSkip)
            .animation(.easeIn(duration: 0.5), value: canSkip)
        }
    }

    private var closeButton: some View {
        Button {
            Haptics.tap(0.3)
            finish()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(PulseColor.textTertiary.opacity(0.6))
                .padding(8)
                .background(Circle().fill(PulseColor.muted.opacity(0.6)))
        }
        .padding(PulseSpace.l)
        .opacity(closeButtonVisible ? 1 : 0)
        .disabled(!closeButtonVisible)
        .animation(.easeIn(duration: 0.5), value: closeButtonVisible)
    }

    @MainActor
    private func tryPurchase() async {
        if let product = entitlements.products.first(where: { $0.id == selectedPlan.productID }) {
            await entitlements.purchase(product)
            finishIfPro()
        } else {
            // Dev fallback when StoreKit products haven't loaded
            entitlements.devTogglePro()
            finish()
        }
    }

    private func finishIfPro() { if entitlements.isPro { finish() } }
    private func finish() { seenOffer = true }
}
