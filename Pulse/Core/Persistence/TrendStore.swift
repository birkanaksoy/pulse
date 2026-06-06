import Foundation
import SwiftData

@Model
final class ScanRecord {
    // All properties default — required for SwiftData + CloudKit sync.
    var timestamp: Date = Date.distantPast
    var pulseScore: Int = 0
    var storageUsed: Int = 0           // 0–100
    var thermalRaw: Int = 0            // 0 nominal · 1 fair · 2 serious · 3 critical
    var batteryLevel: Int?             // 0–100, nil if unknown
    var batteryStateRaw: Int?          // 0 unknown · 1 unplugged · 2 charging · 3 full
    var lowPowerMode: Bool?

    // Deprecated, kept for SwiftData lightweight migration. Do not use.
    var batteryHealth: Int = 0
    var memoryMB: Int = 0

    init(
        timestamp: Date,
        pulseScore: Int,
        storageUsed: Int,
        thermalRaw: Int,
        batteryLevel: Int?,
        batteryStateRaw: Int?,
        lowPowerMode: Bool?
    ) {
        self.timestamp = timestamp
        self.pulseScore = pulseScore
        self.storageUsed = storageUsed
        self.thermalRaw = thermalRaw
        self.batteryLevel = batteryLevel
        self.batteryStateRaw = batteryStateRaw
        self.lowPowerMode = lowPowerMode
    }
}

#if os(iOS)
extension ScanRecord {
    static func from(_ r: ScanResult) -> ScanRecord {
        let thermalRaw: Int = {
            switch r.thermal.state {
            case .nominal: return 0
            case .fair:    return 1
            case .serious: return 2
            case .critical: return 3
            @unknown default: return 0
            }
        }()
        let stateRaw: Int = {
            switch r.battery.state {
            case .unknown:   return 0
            case .unplugged: return 1
            case .charging:  return 2
            case .full:      return 3
            @unknown default: return 0
            }
        }()
        return ScanRecord(
            timestamp: r.timestamp,
            pulseScore: r.pulseScore,
            storageUsed: r.storage.usedPercent,
            thermalRaw: thermalRaw,
            batteryLevel: r.battery.levelKnown ? r.battery.levelPercent : nil,
            batteryStateRaw: stateRaw,
            lowPowerMode: r.battery.isLowPowerMode
        )
    }
}
#endif
