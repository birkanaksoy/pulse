import Foundation
import UserNotifications

/// Trigger-based local notifications fired after each scan. Each rule has a
/// per-category cooldown so the user never gets spammed.
@MainActor
enum SmartNotificationEngine {

    // MARK: - Public

    static func evaluate(latest: ScanResult, records: [ScanRecord]) async {
        guard masterEnabled else { return }
        // Cheap consent check — if the user denied at OS level, do nothing.
        let auth = await UNUserNotificationCenter.current().notificationSettings()
        guard auth.authorizationStatus == .authorized || auth.authorizationStatus == .provisional else { return }

        let candidates: [Notification] = [
            storageCritical(latest),
            storageTight(latest),
            scoreDrop(latest, records: records),
            thermalCritical(latest),
            milestoneExcellent(latest, records: records)
        ].compactMap { $0 }

        for n in candidates {
            guard !inCooldown(n.category) else { continue }
            schedule(n)
            stampCooldown(n.category)
        }
    }

    // MARK: - Settings

    private static let masterKey = "pulse.smart.enabled"
    static var masterEnabled: Bool {
        get { UserDefaults.standard.object(forKey: masterKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: masterKey) }
    }

    static func categoryEnabled(_ c: Category) -> Bool {
        UserDefaults.standard.object(forKey: c.toggleKey) as? Bool ?? true
    }
    static func setCategory(_ c: Category, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: c.toggleKey)
    }

    // MARK: - Categories

    enum Category: String, CaseIterable, Identifiable {
        case storage, performance, thermal, milestone, anomaly
        var id: String { rawValue }
        fileprivate var toggleKey: String { "pulse.smart.\(rawValue)" }

        /// Cooldown in seconds between two fires of this category.
        fileprivate var cooldown: TimeInterval {
            switch self {
            case .storage:     return 3 * 24 * 3600
            case .performance: return 3 * 24 * 3600
            case .thermal:     return 6 * 3600
            case .milestone:   return 24 * 3600
            case .anomaly:     return 12 * 3600
            }
        }

        var displayName: String {
            switch self {
            case .storage:     return String(localized: "Storage warnings")
            case .performance: return String(localized: "Performance drops")
            case .thermal:     return String(localized: "Thermal events")
            case .milestone:   return String(localized: "Milestones")
            case .anomaly:     return String(localized: "Anomalies")
            }
        }
        var displayDescription: String {
            switch self {
            case .storage:     return String(localized: "Heads-up when your storage is filling up.")
            case .performance: return String(localized: "Heads-up when your Pulse Score drops.")
            case .thermal:     return String(localized: "Heads-up when your phone runs hot.")
            case .milestone:   return String(localized: "Cheers when you reach a new high.")
            case .anomaly:     return String(localized: "Heads-up when something unusual happens.")
            }
        }
    }

    // MARK: - Rules

    private static func storageCritical(_ r: ScanResult) -> Notification? {
        guard categoryEnabled(.storage), r.storage.usedPercent >= 90 else { return nil }
        return Notification(
            category: .storage,
            title: String(localized: "Storage almost full"),
            body: String(format: String(localized: "You're at %lld%% used. iOS may start refusing updates above 95%%."), r.storage.usedPercent),
            deepLink: "pulse://home"
        )
    }

    private static func storageTight(_ r: ScanResult) -> Notification? {
        guard categoryEnabled(.storage),
              r.storage.usedPercent >= 85,
              r.storage.usedPercent < 90 else { return nil }
        return Notification(
            category: .storage,
            title: String(localized: "Storage filling up"),
            body: String(format: String(localized: "Your iPhone is at %lld%% used. A bit of cleanup would help."), r.storage.usedPercent),
            deepLink: "pulse://clean"
        )
    }

    private static func scoreDrop(_ latest: ScanResult, records: [ScanRecord]) -> Notification? {
        guard categoryEnabled(.performance) else { return nil }
        let week = recentWeekAvg(records)
        guard let avg = week, avg > 0 else { return nil }
        let delta = avg - Double(latest.pulseScore)
        guard delta >= 15 else { return nil }
        return Notification(
            category: .performance,
            title: String(localized: "Score dropped"),
            body: String(format: String(localized: "Your Pulse is %lld — that's %lld below your weekly average."), latest.pulseScore, Int(delta)),
            deepLink: "pulse://health"
        )
    }

    private static func thermalCritical(_ r: ScanResult) -> Notification? {
        guard categoryEnabled(.thermal) else { return nil }
        guard r.thermal.state == .serious || r.thermal.state == .critical else { return nil }
        return Notification(
            category: .thermal,
            title: String(localized: "Phone is warm"),
            body: r.thermal.state == .critical
                ? String(localized: "iOS may throttle performance. Move to a cooler spot.")
                : String(localized: "Thermal state elevated. Watch heavy apps for a bit."),
            deepLink: "pulse://home"
        )
    }

    private static func milestoneExcellent(_ latest: ScanResult, records: [ScanRecord]) -> Notification? {
        guard categoryEnabled(.milestone) else { return nil }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let recentBest = records.filter { $0.timestamp > yesterday }.map(\.pulseScore).max() ?? 0
        guard latest.pulseScore >= 90, recentBest < 90 else { return nil }
        return Notification(
            category: .milestone,
            title: String(localized: "Excellent Pulse 🎉"),
            body: String(format: String(localized: "You hit %lld today — top form."), latest.pulseScore),
            deepLink: "pulse://health"
        )
    }

    // MARK: - Helpers

    private static func recentWeekAvg(_ records: [ScanRecord]) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let week = records.filter { $0.timestamp >= cutoff }
        guard week.count >= 2 else { return nil }
        return Double(week.map(\.pulseScore).reduce(0, +)) / Double(week.count)
    }

    private static func inCooldown(_ c: Category) -> Bool {
        let key = "pulse.smart.cooldown.\(c.rawValue)"
        let last = UserDefaults.standard.double(forKey: key)
        guard last > 0 else { return false }
        return Date().timeIntervalSince1970 - last < c.cooldown
    }
    private static func stampCooldown(_ c: Category) {
        let key = "pulse.smart.cooldown.\(c.rawValue)"
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
    }

    private static func schedule(_ n: Notification) {
        let content = UNMutableNotificationContent()
        content.title = n.title
        content.body  = n.body
        content.sound = .default
        content.userInfo = ["deepLink": n.deepLink]
        let request = UNNotificationRequest(
            identifier: "pulse.smart.\(n.category.rawValue).\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notification payload

    private struct Notification {
        let category: Category
        let title: String
        let body: String
        let deepLink: String
    }
}
