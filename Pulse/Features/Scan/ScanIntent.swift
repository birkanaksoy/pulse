import AppIntents
import WidgetKit
import Foundation

/// Tapped from the widget to run a quick scan in-place — no app launch.
/// Reads the same probes the main app uses, writes the result to
/// SharedScoreStore (App Group), then reloads timelines.
struct ScanIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Scan"
    static var description = IntentDescription("Run a quick health scan and update the widget.")
    static var isDiscoverable = true
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let battery = BatteryProbe().read()
        let storage = StorageProbe().read()
        let thermal = ThermalProbe().read()
        let score = computeScore(storage: storage.usedPercent, thermal: thermal)

        // Preserve isPro across the snapshot.
        let existing = SharedScoreStore.load()
        SharedScoreStore.save(.init(
            score: score,
            status: statusLabel(for: score),
            timestamp: Date(),
            isPro: existing?.isPro ?? false
        ))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

    // Mirror of ScanResult.pulseScore — kept here so the widget target is self-contained.
    private func computeScore(storage used: Int, thermal: ThermalReading) -> Int {
        let storageScore: Double = {
            switch Double(used) {
            case ..<60:  return 100
            case ..<80:  return 100 - (Double(used) - 60) * 1.5
            case ..<90:  return 70 - (Double(used) - 80) * 3.0
            default:     return max(0, 40 - (Double(used) - 90) * 4.0)
            }
        }()
        let thermalScore = thermal.scoreContribution
        return Int((storageScore * 0.55 + thermalScore * 0.45).rounded())
    }

    private func statusLabel(for score: Int) -> String {
        switch score {
        case 85...: return String(localized: "Excellent")
        case 65...: return String(localized: "Good")
        case 40...: return String(localized: "Fair")
        default:    return String(localized: "Critical")
        }
    }
}
