import Foundation

enum HistoryFilter {
    /// Days of history visible to free users.
    static let freeWindowDays = 14

    /// Returns the slice of records visible to the current user.
    /// Pro: all of them. Free: only the last `freeWindowDays`.
    static func visible(_ records: [ScanRecord], isPro: Bool) -> [ScanRecord] {
        guard !isPro else { return records }
        let cutoff = Calendar.current.date(byAdding: .day, value: -freeWindowDays, to: Date()) ?? Date()
        return records.filter { $0.timestamp >= cutoff }
    }

    /// True when free-tier filtering actually hid something.
    static func isLimited(_ records: [ScanRecord], isPro: Bool) -> Bool {
        guard !isPro else { return false }
        return records.count > visible(records, isPro: false).count
    }
}
