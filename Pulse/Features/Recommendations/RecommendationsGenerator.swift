import Foundation

/// Turns scan signals into concrete recommendations the user can act on.
enum RecommendationsGenerator {
    static func generate(latest: ScanResult?, records: [ScanRecord]) -> [Recommendation] {
        guard let r = latest else { return [] }
        var out: [Recommendation] = []

        // Storage tight
        switch r.storage.usedPercent {
        case 90...:
            out.append(.init(
                id: "storage-critical",
                icon: "internaldrive",
                title: String(localized: "Free up space"),
                body: String(localized: "Storage is at \(r.storage.usedPercent)%. iOS Storage breaks usage down by app."),
                action: .openStorageSettings
            ))
            out.append(.init(
                id: "storage-photos",
                icon: "photo.on.rectangle",
                title: String(localized: "Clear photo trash"),
                body: String(localized: "Recently Deleted holds photos for 30 days. Empty it now to free space immediately."),
                action: .openPhotos
            ))
        case 80...:
            out.append(.init(
                id: "storage-tight",
                icon: "photo.stack",
                title: String(localized: "Trim your photo library"),
                body: String(localized: "Storage is getting tight (\(r.storage.usedPercent)%). Photos are usually the biggest category."),
                action: .openPhotos
            ))
        default:
            break
        }

        // Thermal
        switch r.thermal.state {
        case .critical:
            out.append(.init(
                id: "thermal-critical",
                icon: "thermometer.sun.fill",
                title: String(localized: "Cool your phone down"),
                body: String(localized: "iOS is throttling. Close camera, AR or video apps, and move to a cooler spot."),
                action: .dismiss
            ))
        case .serious:
            out.append(.init(
                id: "thermal-serious",
                icon: "thermometer.high",
                title: String(localized: "Phone is warm"),
                body: String(localized: "Heavy apps may slow down. A short break usually fixes it."),
                action: .dismiss
            ))
        default:
            break
        }

        // Low battery
        if r.battery.levelKnown && r.battery.levelPercent <= 20 && !r.battery.isLowPowerMode {
            out.append(.init(
                id: "low-battery-lpm",
                icon: "leaf",
                title: String(localized: "Turn on Low Power Mode"),
                body: String(localized: "Battery is at \(r.battery.levelPercent)%. Low Power Mode adds an hour or two."),
                action: .openBatterySettings
            ))
        }

        // Score trend down
        if records.count >= 7 {
            let weekly = recentWeekAvg(records)
            if let avg = weekly, avg - Double(r.pulseScore) >= 15 {
                out.append(.init(
                    id: "score-drop",
                    icon: "chart.xyaxis.line",
                    title: String(localized: "Score is below trend"),
                    body: String(localized: "You're \(Int(avg - Double(r.pulseScore))) points under your weekly average. Take a look at what changed."),
                    action: .openHealth
                ))
            }
        }

        // Nothing actionable → encourage habit
        if out.isEmpty && r.pulseScore >= 85 {
            out.append(.init(
                id: "stay-on-it",
                icon: "checkmark.seal",
                title: String(localized: "All clear"),
                body: String(localized: "Your phone is in great shape. Keep the streak alive — scan again tomorrow."),
                action: .dismiss
            ))
        }

        return Array(out.prefix(4))
    }

    private static func recentWeekAvg(_ records: [ScanRecord]) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let week = records.filter { $0.timestamp >= cutoff }
        guard week.count >= 2 else { return nil }
        return Double(week.map(\.pulseScore).reduce(0, +)) / Double(week.count)
    }
}
