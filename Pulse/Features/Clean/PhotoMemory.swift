import Foundation

/// Persisted set of `PHAsset.localIdentifier`s the user has explicitly kept.
/// PhotoQueue filters these out so the same photo isn't shown twice.
enum PhotoMemory {
    private static let key = "pulse.memory.kept"

    static var kept: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func recordKept(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        var all = kept
        ids.forEach { all.insert($0) }
        UserDefaults.standard.set(Array(all), forKey: key)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
