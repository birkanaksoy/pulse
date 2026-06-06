import BackgroundTasks
import WidgetKit
import Foundation
import os.log

/// Silent weekly scan using BGAppRefreshTask. iOS may schedule the work at its
/// discretion (usually overnight on charge). No notification fires from this —
/// the user-visible weekly reminder comes from NotificationScheduler instead.
@MainActor
enum BackgroundScanner {
    static let taskID = "app.pulse.weeklyScan"
    private static let log = Logger(subsystem: "app.pulse", category: "background")

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            Task { await handle(task: task) }
        }
        log.info("Background task registered: \(taskID, privacy: .public)")
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        // At least 6 days from now — iOS may run it later but not sooner.
        request.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 6, to: Date())
        do {
            try BGTaskScheduler.shared.submit(request)
            log.info("Scheduled next background scan")
        } catch {
            log.error("Failed to schedule: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func handle(task: BGAppRefreshTask) async {
        // Always reschedule the next run before doing work.
        scheduleNext()

        let work = Task {
            let battery = BatteryProbe().read()
            let storage = StorageProbe().read()
            let thermal = ThermalProbe().read()
            let score = computeScore(storage: storage.usedPercent, thermal: thermal)
            let snap = SharedScoreStore.load()
            SharedScoreStore.save(.init(
                score: score,
                status: statusLabel(for: score),
                timestamp: Date(),
                isPro: snap?.isPro ?? false
            ))
            _ = battery   // silenced — kept so future versions can persist it
            WidgetCenter.shared.reloadAllTimelines()
            // If a Live Activity is currently displayed, refresh it with the
            // new score so the user's Lock Screen / Dynamic Island stays in sync.
            await MainActor.run {
                ScanLiveActivityController.refreshActiveWith(score: score)
            }
        }

        task.expirationHandler = { work.cancel() }
        await work.value
        task.setTaskCompleted(success: true)
    }

    private static func computeScore(storage used: Int, thermal: ThermalReading) -> Int {
        let storageScore: Double = {
            switch Double(used) {
            case ..<60:  return 100
            case ..<80:  return 100 - (Double(used) - 60) * 1.5
            case ..<90:  return 70 - (Double(used) - 80) * 3.0
            default:     return max(0, 40 - (Double(used) - 90) * 4.0)
            }
        }()
        return Int((storageScore * 0.55 + thermal.scoreContribution * 0.45).rounded())
    }

    private static func statusLabel(for score: Int) -> String {
        switch score {
        case 85...: return String(localized: "Excellent")
        case 65...: return String(localized: "Good")
        case 40...: return String(localized: "Fair")
        default:    return String(localized: "Critical")
        }
    }
}
