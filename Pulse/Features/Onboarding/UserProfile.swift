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

enum OwnershipAge: String, CaseIterable, Identifiable, Codable {
    case lessThan6Months, sixToTwelveMonths, oneToTwoYears, twoToThreeYears, threePlusYears
    var id: String { rawValue }
    var label: String {
        switch self {
        case .lessThan6Months:   return String(localized: "Less than 6 months")
        case .sixToTwelveMonths: return String(localized: "6–12 months")
        case .oneToTwoYears:     return String(localized: "1–2 years")
        case .twoToThreeYears:   return String(localized: "2–3 years")
        case .threePlusYears:    return String(localized: "3+ years")
        }
    }
}

enum CleaningHabit: String, CaseIterable, Identifiable, Codable {
    case never, sometimes, regular
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .never:     return "📥"
        case .sometimes: return "🧽"
        case .regular:   return "✨"
        }
    }
    var label: String {
        switch self {
        case .never:     return String(localized: "Never — I just let it pile up")
        case .sometimes: return String(localized: "Sometimes — every few months")
        case .regular:   return String(localized: "Regularly — I like a clean phone")
        }
    }
}

/// Persisted on first launch. Anonymous, never leaves the device.
struct UserProfile: Codable, Equatable {
    var detectedModel: String
    var selectedModel: String?
    var ownershipAge: OwnershipAge?
    var concerns: [UserConcern] = []   // multi-select
    var cleaningHabit: CleaningHabit?
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

enum DeviceModel {
    static var displayName: String {
        mapping[identifier] ?? "iPhone"
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

    static let pickerList: [String] = [
        "iPhone 17 Pro", "iPhone 17",
        "iPhone 16 Pro", "iPhone 16",
        "iPhone 15 Pro", "iPhone 15",
        "iPhone 14", "iPhone 13",
        "iPhone SE", "Other"
    ]

    private static let mapping: [String: String] = [
        "iPhone18,3": "iPhone 17 Pro Max",
        "iPhone18,2": "iPhone 17 Pro",
        "iPhone18,1": "iPhone 17",
        "iPhone17,1": "iPhone 16 Pro Max",
        "iPhone17,2": "iPhone 16 Pro",
        "iPhone17,3": "iPhone 16 Plus",
        "iPhone17,4": "iPhone 16",
        "iPhone17,5": "iPhone 16e",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,6": "iPhone SE (3rd gen)",
        "iPhone12,8": "iPhone SE (2nd gen)",
    ]
}
