import SwiftUI
import UIKit

enum PulseColor {
    // Brand — same in both modes (looks good light/dark).
    static let blue500 = Color(red: 0.184, green: 0.420, blue: 1.000)
    static let blue300 = Color(red: 0.431, green: 0.765, blue: 1.000)

    // Status colors — same in both modes.
    static let excellent = Color(red: 0.129, green: 0.753, blue: 0.478)
    static let good      = blue500
    static let fair      = Color(red: 0.961, green: 0.647, blue: 0.141)
    static let critical  = Color(red: 0.937, green: 0.267, blue: 0.267)

    // Dynamic surfaces / text — adapt to light/dark.
    static let blue50  = dyn(
        light: UIColor(red: 0.933, green: 0.953, blue: 1.000, alpha: 1),
        dark:  UIColor(red: 0.094, green: 0.137, blue: 0.243, alpha: 1)
    )
    static let canvas = dyn(
        light: .white,
        dark:  UIColor(red: 0.043, green: 0.071, blue: 0.125, alpha: 1)
    )
    static let muted = dyn(
        light: UIColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1),
        dark:  UIColor(red: 0.078, green: 0.094, blue: 0.157, alpha: 1)
    )
    static let card = dyn(
        light: .white,
        dark:  UIColor(red: 0.102, green: 0.122, blue: 0.196, alpha: 1)
    )
    static let stroke = dyn(
        light: UIColor(red: 0.933, green: 0.941, blue: 0.957, alpha: 1),
        dark:  UIColor(red: 0.165, green: 0.188, blue: 0.267, alpha: 1)
    )

    static let textPrimary = dyn(
        light: UIColor(red: 0.043, green: 0.071, blue: 0.125, alpha: 1),
        dark:  UIColor(red: 0.941, green: 0.949, blue: 0.973, alpha: 1)
    )
    static let textSecondary = dyn(
        light: UIColor(red: 0.361, green: 0.392, blue: 0.451, alpha: 1),
        dark:  UIColor(red: 0.627, green: 0.659, blue: 0.722, alpha: 1)
    )
    static let textTertiary = dyn(
        light: UIColor(red: 0.565, green: 0.596, blue: 0.651, alpha: 1),
        dark:  UIColor(red: 0.420, green: 0.451, blue: 0.514, alpha: 1)
    )

    static let ringGradient = LinearGradient(
        colors: [blue500, blue300],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Helper

    private static func dyn(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
}

enum PulseStatus {
    case excellent, good, fair, critical

    init(score: Int) {
        switch score {
        case 85...: self = .excellent
        case 65...: self = .good
        case 40...: self = .fair
        default:    self = .critical
        }
    }

    var label: String {
        switch self {
        case .excellent: return String(localized: "Excellent")
        case .good:      return String(localized: "Good")
        case .fair:      return String(localized: "Fair")
        case .critical:  return String(localized: "Critical")
        }
    }

    var color: Color {
        switch self {
        case .excellent: return PulseColor.excellent
        case .good:      return PulseColor.good
        case .fair:      return PulseColor.fair
        case .critical:  return PulseColor.critical
        }
    }
}
