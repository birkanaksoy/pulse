import SwiftUI
import SwiftData

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
    @AppStorage("pulse.didOnboard") private var didOnboard = false

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
            .tint(PulseColor.blue500)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        }
        .modelContainer(container)
    }
}
