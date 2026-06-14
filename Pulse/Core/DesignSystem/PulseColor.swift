import SwiftUI
import UIKit

enum PulseColor {
    // MARK: - Brand (same in both modes)
    static let blue500 = Color(red: 0.184, green: 0.420, blue: 1.000)
    static let blue300 = Color(red: 0.431, green: 0.765, blue: 1.000)
    static let blue700 = Color(red: 0.110, green: 0.310, blue: 0.870)

    // Accent — for Pro / premium moments
    static let purple = Color(red: 0.510, green: 0.290, blue: 0.980)
    static let teal   = Color(red: 0.027, green: 0.749, blue: 0.808)

    // MARK: - Status (same in both modes)
    static let excellent = Color(red: 0.129, green: 0.753, blue: 0.478)
    static let good      = blue500
    static let fair      = Color(red: 0.961, green: 0.647, blue: 0.141)
    static let critical  = Color(red: 0.937, green: 0.267, blue: 0.267)

    // MARK: - Dynamic surfaces
    static let blue50  = dyn(
        light: UIColor(red: 0.933, green: 0.953, blue: 1.000, alpha: 1),
        dark:  UIColor(red: 0.094, green: 0.137, blue: 0.243, alpha: 1)
    )
    static let canvas = dyn(
        light: .white,
        dark:  UIColor(red: 0.039, green: 0.063, blue: 0.118, alpha: 1)
    )
    static let muted = dyn(
        light: UIColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1),
        dark:  UIColor(red: 0.071, green: 0.090, blue: 0.149, alpha: 1)
    )
    static let card = dyn(
        light: .white,
        dark:  UIColor(red: 0.110, green: 0.133, blue: 0.204, alpha: 1)
    )
    static let cardElevated = dyn(
        light: .white,
        dark:  UIColor(red: 0.137, green: 0.165, blue: 0.247, alpha: 1)
    )
    static let stroke = dyn(
        light: UIColor(red: 0.933, green: 0.941, blue: 0.957, alpha: 1),
        dark:  UIColor(red: 0.180, green: 0.208, blue: 0.290, alpha: 1)
    )
    static let strokeStrong = dyn(
        light: UIColor(red: 0.871, green: 0.886, blue: 0.918, alpha: 1),
        dark:  UIColor(red: 0.247, green: 0.275, blue: 0.357, alpha: 1)
    )

    static let textPrimary = dyn(
        light: UIColor(red: 0.043, green: 0.071, blue: 0.125, alpha: 1),
        dark:  UIColor(red: 0.957, green: 0.965, blue: 0.984, alpha: 1)
    )
    static let textSecondary = dyn(
        light: UIColor(red: 0.361, green: 0.392, blue: 0.451, alpha: 1),
        dark:  UIColor(red: 0.671, green: 0.706, blue: 0.769, alpha: 1)
    )
    static let textTertiary = dyn(
        light: UIColor(red: 0.565, green: 0.596, blue: 0.651, alpha: 1),
        dark:  UIColor(red: 0.467, green: 0.498, blue: 0.561, alpha: 1)
    )

    // MARK: - Gradients

    /// Primary brand gradient — used on rings, CTAs, hero glyphs.
    static let ringGradient = LinearGradient(
        colors: [blue500, blue300],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Vibrant Pro gradient — used for premium moments (Pro insights, paywall).
    static let proGradient = LinearGradient(
        colors: [blue500, purple, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Mesh-style ambient gradient for hero backgrounds.
    static func ambientGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.18), blue300.opacity(0.10), tint.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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

    var gradient: LinearGradient {
        switch self {
        case .excellent:
            return LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .good:
            return LinearGradient(colors: [PulseColor.blue500, PulseColor.blue300],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .fair:
            return LinearGradient(colors: [PulseColor.fair, PulseColor.blue300],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .critical:
            return LinearGradient(colors: [PulseColor.critical, PulseColor.fair],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
