import Foundation

struct LiveInsight: Identifiable {
    let id = UUID()
    var icon: String
    var text: String
}

/// Generates user-visible insights from REAL scan data only.
/// All text uses `String(localized:)` so the String Catalog can translate.
enum InsightsGenerator {
    static func generate(latest: ScanResult?, records: [ScanRecord]) -> [LiveInsight] {
        guard let r = latest else { return [] }
        var out: [LiveInsight] = []

        let p = r.storage.usedPercent
        switch p {
        case 90...:
            out.append(.init(
                icon: "exclamationmark.octagon",
                text: String(localized: "Storage at \(p)% — clear space soon")
            ))
        case 80...:
            out.append(.init(
                icon: "exclamationmark.triangle",
                text: String(localized: "Storage at \(p)% — getting tight")
            ))
        case 60...:
            out.append(.init(
                icon: "internaldrive",
                text: String(localized: "Storage at \(p)% — comfortable")
            ))
        default:
            out.append(.init(
                icon: "checkmark.circle",
                text: String(localized: "Storage healthy at \(p)%")
            ))
        }

        switch r.thermal.state {
        case .serious:
            out.append(.init(
                icon: "thermometer.high",
                text: String(localized: "Thermal state warm — iOS may throttle performance")
            ))
        case .critical:
            out.append(.init(
                icon: "thermometer.sun.fill",
                text: String(localized: "Thermal state hot — consider a cooler environment")
            ))
        default: break
        }

        if r.battery.isLowPowerMode {
            out.append(.init(
                icon: "leaf",
                text: String(localized: "Low Power Mode is on")
            ))
        }

        if r.battery.levelKnown && r.battery.levelPercent <= 20 {
            let lvl = r.battery.levelPercent
            out.append(.init(
                icon: "battery.25percent",
                text: String(localized: "Battery at \(lvl)% — consider charging")
            ))
        }

        if records.count >= 3 {
            let recent = Array(records.prefix(3))
            let oldest = recent.last!.pulseScore
            let newest = recent.first!.pulseScore
            let delta = newest - oldest
            if delta >= 5 {
                out.append(.init(
                    icon: "arrow.up.right",
                    text: String(localized: "Score rose \(delta) over your last 3 scans")
                ))
            } else if delta <= -5 {
                let down = -delta
                out.append(.init(
                    icon: "arrow.down.right",
                    text: String(localized: "Score fell \(down) over your last 3 scans")
                ))
            }
        }

        return Array(out.prefix(4))
    }
}
