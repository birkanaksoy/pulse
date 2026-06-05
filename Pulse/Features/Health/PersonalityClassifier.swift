import Foundation

struct Personality {
    var name: String
    var emoji: String
    var subtitle: String
}

enum PersonalityClassifier {
    static func classify(_ records: [ScanRecord], latest: ScanRecord?) -> Personality {
        guard let l = latest else {
            return Personality(
                name: String(localized: "Unknown"),
                emoji: "🫥",
                subtitle: String(localized: "Run a scan to find out.")
            )
        }

        let thermalEvents = records.prefix(7).filter { $0.thermalRaw >= 2 }.count
        let lowPowerOften = records.prefix(7).filter { $0.lowPowerMode == true }.count >= 3

        switch (l.pulseScore, l.storageUsed, l.thermalRaw) {
        case (85..., ..<60, 0):
            return Personality(
                name: String(localized: "Stable & Healthy"),
                emoji: "🟢",
                subtitle: String(localized: "Cool, roomy, and calm.")
            )
        case (_, 85..., _):
            return Personality(
                name: String(localized: "Hoarder"),
                emoji: "📦",
                subtitle: String(localized: "Storage is your bottleneck.")
            )
        case (_, _, 2...):
            return Personality(
                name: String(localized: "Marathon Runner"),
                emoji: "🥵",
                subtitle: String(localized: "Working hot. Give it a rest.")
            )
        case (40..<65, _, _) where lowPowerOften:
            return Personality(
                name: String(localized: "Power Sipper"),
                emoji: "🪫",
                subtitle: String(localized: "Mostly in Low Power Mode.")
            )
        case (40..<65, _, _):
            return Personality(
                name: String(localized: "Overworked Office Worker"),
                emoji: "😴",
                subtitle: String(localized: "High load, low rest.")
            )
        case (..<40, _, _):
            return Personality(
                name: String(localized: "Burnt Out"),
                emoji: "🚨",
                subtitle: String(localized: "Needs attention.")
            )
        default:
            let subtitle = thermalEvents > 0
                ? String(localized: "Performance trending warm.")
                : String(localized: "Performance holding steady.")
            return Personality(
                name: String(localized: "Steady Performer"),
                emoji: "🙂",
                subtitle: subtitle
            )
        }
    }
}
