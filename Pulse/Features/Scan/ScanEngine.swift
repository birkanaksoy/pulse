import Foundation
import Observation

struct ScanResult: Equatable {
    var battery: BatteryReading
    var storage: StorageReading
    var thermal: ThermalReading
    var timestamp: Date

    /// Honest weighted score from signals iOS actually exposes:
    /// storage pressure (55%) + thermal state (45%).
    /// Low Power Mode is shown as context but doesn't dock the score —
    /// the user may have enabled it deliberately.
    var pulseScore: Int {
        let storageScore = Self.storageScore(used: storage.usedPercent)
        let thermalScore = thermal.scoreContribution
        let weighted = storageScore * 0.55 + thermalScore * 0.45
        return Int(weighted.rounded())
    }

    /// Piecewise: < 60% used → great. 60–80 → fair. 80–90 → poor. 90+ → critical.
    private static func storageScore(used: Int) -> Double {
        let u = Double(used)
        switch u {
        case ..<60:  return 100
        case ..<80:  return 100 - (u - 60) * 1.5                // 100 → 70
        case ..<90:  return 70 - (u - 80) * 3.0                 // 70 → 40
        default:     return max(0, 40 - (u - 90) * 4.0)         // 40 → 0
        }
    }
}

@Observable
@MainActor
final class ScanEngine {
    enum Phase: Equatable { case idle, scanning(progress: Double), complete }

    var phase: Phase = .idle
    var lastResult: ScanResult?

    private let battery = BatteryProbe()
    private let storage = StorageProbe()
    private let thermal = ThermalProbe()

    func runFullScan() async {
        Haptics.scanStart()
        phase = .scanning(progress: 0)
        let b = await step(0.33) { self.battery.read() }
        let s = await step(0.66) { self.storage.read() }
        let t = await step(1.00) { self.thermal.read() }

        let result = ScanResult(battery: b, storage: s, thermal: t, timestamp: Date())
        lastResult = result
        phase = .complete
        Haptics.scanComplete()
    }

    private func step<T>(_ progress: Double, _ work: () -> T) async -> T {
        try? await Task.sleep(nanoseconds: 500_000_000)
        let value = work()
        phase = .scanning(progress: progress)
        return value
    }
}
