import UIKit
import Foundation

/// What iOS actually exposes publicly. No fake health number.
struct BatteryReading: Equatable {
    var levelPercent: Int          // 0–100, current charge (or nil-equivalent -1)
    var state: UIDevice.BatteryState
    var isLowPowerMode: Bool
    var levelKnown: Bool           // false on Simulator

    var stateLabel: String {
        switch state {
        case .charging:  return "Charging"
        case .full:      return "Full"
        case .unplugged: return "Unplugged"
        case .unknown:   return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

struct BatteryProbe {
    func read() -> BatteryReading {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let raw = UIDevice.current.batteryLevel
        let known = raw >= 0
        let level = known ? Int((raw * 100).rounded()) : 0
        return BatteryReading(
            levelPercent: level,
            state: UIDevice.current.batteryState,
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            levelKnown: known
        )
    }
}
