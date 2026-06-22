import SwiftUI

@main
struct PulseApp: App {
    @State private var entitlements = EntitlementStore()
    @AppStorage("pulse.didOnboard") private var didOnboard = false
    @AppStorage("pulse.seenOffer") private var seenOffer = false

    init() {
        Analytics.track(.appLaunched)
    }

    var body: some Scene {
        WindowGroup {
            LaunchAnimation {
                rootContent
                    .environment(entitlements)
                    .tint(PulseColor.blue500)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if !didOnboard {
            OnboardingView(didOnboard: $didOnboard)
        } else if !seenOffer && !entitlements.isPro {
            SpecialOfferPaywallView(seenOffer: $seenOffer)
        } else {
            RootView()
        }
    }
}
