import Foundation

/// Per-day sweep counter. Free tier gets one sweep per calendar day; Pro is
/// unlimited. The limit is what makes Pro genuinely valuable in v2.
enum SweepLimits {
    static let freeDailyLimit = 1

    static var todayCount: Int {
        UserDefaults.standard.integer(forKey: todayKey)
    }

    static func recordStart() {
        UserDefaults.standard.set(todayCount + 1, forKey: todayKey)
    }

    static func canStart(isPro: Bool) -> Bool {
        isPro || todayCount < freeDailyLimit
    }

    static var remainingToday: Int {
        max(0, freeDailyLimit - todayCount)
    }

    private static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "pulse.sweep.daily.\(f.string(from: Date()))"
    }
}
