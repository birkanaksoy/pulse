import Foundation

/// All-time bytes the user has freed through Pulse's cleaner.
/// Persisted in UserDefaults; shown as a brag-worthy stat in Clean & Home.
enum BytesFreedTracker {
    private static let key = "pulse.bytesFreed"
    private static let sessionKey = "pulse.bytesFreed.session.\(today)"

    static var allTime: Int64 {
        Int64(UserDefaults.standard.double(forKey: key))
    }

    static var today: Int64 {
        Int64(UserDefaults.standard.double(forKey: sessionKey))
    }

    static func add(_ bytes: Int64) {
        guard bytes > 0 else { return }
        let total = allTime + bytes
        let day = Int64(UserDefaults.standard.double(forKey: sessionKey)) + bytes
        UserDefaults.standard.set(Double(total), forKey: key)
        UserDefaults.standard.set(Double(day), forKey: sessionKey)
    }

    static var formattedAllTime: String {
        ByteCountFormatter.string(fromByteCount: allTime, countStyle: .file)
    }

    private static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
