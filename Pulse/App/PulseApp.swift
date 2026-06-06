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

    init() {
        // Wire notification delegate so taps route via the router.
        NotificationCenterDelegate.shared.router = nil   // set in onAppear, see below
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
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
            }
        }
        .modelContainer(container)
    }
}
