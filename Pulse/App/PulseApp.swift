import SwiftUI
import SwiftData
import UserNotifications

@main
struct PulseApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: ScanRecord.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @State private var entitlements = EntitlementStore()
    @State private var router = DeepLinkRouter()
    @AppStorage("pulse.didOnboard") private var didOnboard = false
    @AppStorage("pulse.seenOffer") private var seenOffer = false

    init() {
        NotificationCenterDelegate.shared.router = nil
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
        BackgroundScanner.register()
        TelemetryAnalyticsBootstrap.start()
        Analytics.track(.appLaunched)
    }

    var body: some Scene {
        WindowGroup {
            LaunchAnimation {
                rootContent
                    .environment(entitlements)
                    .environment(router)
                    .tint(PulseColor.blue500)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .onOpenURL { url in router.handle(url: url) }
                    .task {
                        NotificationCenterDelegate.shared.router = router
                        BackgroundScanner.scheduleNext()
                    }
            }
        }
        .modelContainer(container)
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
