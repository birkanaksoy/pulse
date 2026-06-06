import SwiftUI
import SwiftData

@main
struct PulseWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
        .modelContainer(WatchContainer.shared)
    }
}

/// CloudKit-mirrored SwiftData container — same private DB as the iOS app, so
/// records sync when both devices are online.
enum WatchContainer {
    static let shared: ModelContainer = {
        let config = ModelConfiguration(
            "PulseStore",
            schema: Schema([ScanRecord.self]),
            cloudKitDatabase: .private("iCloud.com.birkan.pulse")
        )
        do {
            return try ModelContainer(for: ScanRecord.self, configurations: config)
        } catch {
            return try! ModelContainer(for: ScanRecord.self)
        }
    }()
}
