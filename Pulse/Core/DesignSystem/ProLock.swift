import SwiftUI

struct ProLock<Content: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var content: () -> Content
    @Environment(EntitlementStore.self) private var entitlements
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            content()
                .blur(radius: entitlements.isPro ? 0 : 8)
                .allowsHitTesting(entitlements.isPro)
                .disabled(!entitlements.isPro)

            if !entitlements.isPro {
                Button { showingPaywall = true } label: {
                    VStack(spacing: PulseSpace.s) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(PulseColor.ringGradient))
                        Text(title)
                            .font(PulseFont.titleM)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text(subtitle)
                            .font(PulseFont.callout)
                            .foregroundStyle(PulseColor.textSecondary)
                            .multilineTextAlignment(.center)
                        Text("Unlock with Pro")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, PulseSpace.l)
                            .padding(.vertical, PulseSpace.s)
                            .background(Capsule().fill(PulseColor.ringGradient))
                            .padding(.top, PulseSpace.s)
                    }
                    .padding(PulseSpace.xl)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }
}
