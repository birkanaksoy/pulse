import Foundation

enum SharedScoreStore {
    static let suiteName = "group.com.birkan.pulse.shared"
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    struct Snapshot: Codable, Equatable {
        var score: Int
        var status: String
        var timestamp: Date
        var isPro: Bool = false
    }

    private static let key = "pulse.snapshot"

    static func save(_ snapshot: Snapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    static func load() -> Snapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
