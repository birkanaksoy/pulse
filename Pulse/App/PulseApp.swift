import SwiftUI
import SwiftData
import UserNotifications

@main
struct PulseApp: App {
    let container: ModelContainer = {
        // iCloud-backed store: SwiftData mirrors records to the user's private
        // CloudKit DB so reinstalls and second devices stay in sync.
        let config = ModelConfiguration(
            "PulseStore",
            schema: Schema([ScanRecord.self]),
            cloudKitDatabase: .private("iCloud.com.birkan.pulse")
        )
        do {
            return try ModelContainer(for: ScanRecord.self, configurations: config)
        } catch {
            // Fall back to local-only store if CloudKit isn't configured.
            return try! ModelContainer(for: ScanRecord.self)
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
