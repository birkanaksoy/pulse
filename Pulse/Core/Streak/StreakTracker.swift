import Foundation

struct StreakState: Equatable {
    /// Consecutive calendar days with at least one scan, ending today (or yesterday if today empty).
    var current: Int
    /// All-time longest streak.
    var best: Int
    /// True iff today has a scan — used to know if the streak is "live".
    var scannedToday: Bool

    var isMilestone: Bool { [3, 7, 14, 30, 60, 100, 365].contains(current) }
}

enum StreakTracker {
    /// Computes the streak state from a sorted-DESC array of records.
    static func compute(_ records: [ScanRecord], today: Date = Date()) -> StreakState {
        guard !records.isEmpty else {
            return StreakState(current: 0, best: 0, scannedToday: false)
        }

        let cal = Calendar.current
        // Map each record to its start-of-day (de-dup multi-scan days).
        let days = Set(records.map { cal.startOfDay(for: $0.timestamp) })
        let todayStart = cal.startOfDay(for: today)
        let scannedToday = days.contains(todayStart)

        // Current streak: walk back day by day from today (or yesterday if today empty).
        var current = 0
        var cursor = scannedToday ? todayStart
                                 : (cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart)
        while days.contains(cursor) {
            current += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // Best streak: longest run of consecutive days across the full set.
        let sortedDays = days.sorted()
        var best = 0
        var run = 0
        var prev: Date?
        for d in sortedDays {
            if let p = prev, cal.dateComponents([.day], from: p, to: d).day == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            prev = d
        }

        return StreakState(current: current, best: max(best, current), scannedToday: scannedToday)
    }
}
