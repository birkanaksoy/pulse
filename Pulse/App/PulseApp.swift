import SwiftUI
import SwiftData
import UserNotifications

@main
struct PulseApp: App {
    let container: ModelContainer = {
        // Local-only for the first build. iCloud sync re-enables when bundle
        // IDs + container are registered in Apple Developer portal.
        do {
            return try ModelContainer(for: ScanRecord.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @State private var entitlements = EntitlementStore()
    @State private var router = DeepLinkRouter()
    @AppStorage("pulse.didOnboard") private var didOnboard = false

    init() {
        // Wire notification delegate so taps route via the router.
        NotificationCenterDelegate.shared.router = nil
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
        // Register the silent weekly background scan.
        BackgroundScanner.register()
        // Anonymous analytics — falls back to local logger if app ID not set.
        TelemetryAnalyticsBootstrap.start()
        Analytics.track(.appLaunched)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if didOnboard {
                    RootView()
                } else {
                    OnboardingView(didOnboard: $didOnboard)
                }
            }
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
        .modelContainer(container)
    }
}
