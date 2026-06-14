import SwiftUI

enum PulseFont {
    static let hero      = Font.system(size: 64, weight: .semibold, design: .rounded)
    static let titleXL   = Font.system(size: 34, weight: .bold,     design: .default)
    static let titleL    = Font.system(size: 28, weight: .semibold, design: .default)
    static let titleM    = Font.system(size: 22, weight: .semibold, design: .default)
    static let body      = Font.system(size: 17, weight: .regular,  design: .default)
    static let callout   = Font.system(size: 15, weight: .medium,   design: .default)
    static let footnote  = Font.system(size: 13, weight: .regular,  design: .default)
    static let metric    = Font.system(size: 15, weight: .medium,   design: .monospaced)
}

enum PulseRadius {
    static let card: CGFloat = 20
    static let button: CGFloat = 16
    static let pill: CGFloat = 999
    static let sheet: CGFloat = 28
}

enum PulseSpace {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

struct PulseCardStyle: ViewModifier {
    var elevated: Bool = false
    var padding: CGFloat = PulseSpace.xl

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .fill(elevated ? PulseColor.cardElevated : PulseColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .strokeBorder(PulseColor.stroke, lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(elevated ? 0.06 : 0.03), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(elevated ? 0.10 : 0.05), radius: 18, x: 0, y: 10)
    }
}

struct PulseGlassCardStyle: ViewModifier {
    var padding: CGFloat = PulseSpace.xl

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
    }
}

extension View {
    func pulseCard(elevated: Bool = false, padding: CGFloat = PulseSpace.xl) -> some View {
        modifier(PulseCardStyle(elevated: elevated, padding: padding))
    }

    func pulseGlassCard(padding: CGFloat = PulseSpace.xl) -> some View {
        modifier(PulseGlassCardStyle(padding: padding))
    }
}
