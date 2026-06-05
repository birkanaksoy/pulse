import Foundation

struct ThermalReading: Equatable {
    var state: ProcessInfo.ThermalState
    var label: String {
        switch state {
        case .nominal:  return "Normal"
        case .fair:     return "Fair"
        case .serious:  return "Warm"
        case .critical: return "Hot"
        @unknown default: return "Unknown"
        }
    }
    var scoreContribution: Double {
        switch state {
        case .nominal:  return 100
        case .fair:     return 80
        case .serious:  return 50
        case .critical: return 20
        @unknown default: return 70
        }
    }
}

struct ThermalProbe {
    func read() -> ThermalReading {
        ThermalReading(state: ProcessInfo.processInfo.thermalState)
    }
}
