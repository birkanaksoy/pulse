import Foundation
import UIKit

struct Recommendation: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let action: Action

    enum Action: Equatable {
        case openPhotos
        case openStorageSettings
        case openBatterySettings
        case openLowPowerSettings
        case openHealth
        case runScan
        case dismiss

        var label: String {
            switch self {
            case .openPhotos:           return String(localized: "Open Photos")
            case .openStorageSettings:  return String(localized: "Open Storage")
            case .openBatterySettings:  return String(localized: "Open Battery")
            case .openLowPowerSettings: return String(localized: "Open Settings")
            case .openHealth:           return String(localized: "See trend")
            case .runScan:              return String(localized: "Run scan")
            case .dismiss:              return String(localized: "Got it")
            }
        }

        var systemImage: String {
            switch self {
            case .openPhotos:           return "photo.stack"
            case .openStorageSettings:  return "internaldrive"
            case .openBatterySettings:  return "battery.100.bolt"
            case .openLowPowerSettings: return "leaf"
            case .openHealth:           return "chart.xyaxis.line"
            case .runScan:              return "play.fill"
            case .dismiss:              return "checkmark"
            }
        }

        @MainActor
        func perform() {
            let urlString: String? = {
                switch self {
                case .openPhotos:           return "photos-redirect://"
                case .openStorageSettings:  return "App-Prefs:General&path=STORAGE_MGMT_SETTINGS"
                case .openBatterySettings:  return "App-Prefs:Battery"
                case .openLowPowerSettings: return "App-Prefs:BATTERY_USAGE"
                case .openHealth:           return "pulse://health"
                case .runScan:              return "pulse://home/scan"
                case .dismiss:              return nil
                }
            }()
            guard let s = urlString, let url = URL(string: s) else { return }
            UIApplication.shared.open(url)
        }
    }
}
