import Foundation
import UIKit

enum UserConcern: String, CaseIterable, Identifiable, Codable {
    case storage, speed, battery, curious
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .storage: return "📦"
        case .speed:   return "🐌"
        case .battery: return "🔋"
        case .curious: return "🤔"
        }
    }
    var label: String {
        switch self {
        case .storage: return String(localized: "Storage filling up")
        case .speed:   return String(localized: "Phone feels slow")
        case .battery: return String(localized: "Battery dies fast")
        case .curious: return String(localized: "Just curious")
        }
    }
}

/// Persisted on first launch. Anonymous, never leaves the device.
struct UserProfile: Codable, Equatable {
    var detectedModel: String   // e.g. "iPhone 15 Pro"
    var selectedModel: String   // user can override
    var concern: UserConcern?
}

@MainActor
enum UserProfileStore {
    private static let key = "pulse.userProfile"

    static var current: UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        return profile
    }

    static func save(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// Maps Apple's machine identifier ("iPhone17,2") to a marketing name.
enum DeviceModel {
    static var displayName: String {
        let id = identifier
        return mapping[id] ?? "iPhone"
    }

    static var identifier: String {
        var info = utsname()
        uname(&info)
        let mirror = Mirror(reflecting: info.machine)
        return mirror.children.reduce("") { acc, child in
            guard let v = child.value as? Int8, v != 0 else { return acc }
            return acc + String(UnicodeScalar(UInt8(v)))
        }
    }

    /// Common picker list — keeps onboarding short. User can pick "Other" if
    /// they're on something old/unusual.
    static let pickerList: [String] = [
        "iPhone 17 Pro", "iPhone 17",
        "iPhone 16 Pro", "iPhone 16",
        "iPhone 15 Pro", "iPhone 15",
        "iPhone 14", "iPhone 13",
        "iPhone SE", "Other"
    ]

    private static let mapping: [String: String] = [
        // iPhone 17 family (Sept 2025)
        "iPhone18,3": "iPhone 17 Pro Max",
        "iPhone18,2": "iPhone 17 Pro",
        "iPhone18,1": "iPhone 17",
        // iPhone 16 family
        "iPhone17,1": "iPhone 16 Pro Max",
        "iPhone17,2": "iPhone 16 Pro",
        "iPhone17,3": "iPhone 16 Plus",
        "iPhone17,4": "iPhone 16",
        "iPhone17,5": "iPhone 16e",
        // iPhone 15 family
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        // iPhone 14 family
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        // iPhone 13 family
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        // iPhone 12 / SE
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,6": "iPhone SE (3rd gen)",
        "iPhone12,8": "iPhone SE (2nd gen)",
    ]
}
