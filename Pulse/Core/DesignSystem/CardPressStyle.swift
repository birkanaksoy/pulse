import SwiftUI

/// Subtle press feedback for tappable cards. Slight scale + shadow attenuation.
/// Plays a soft haptic on initial press so the interaction feels alive.
struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale(for: configuration))
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7),
                       value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { Haptics.tap(0.25) }
            }
    }

    private func scale(for cfg: Configuration) -> CGFloat {
        guard !reduceMotion else { return 1 }
        return cfg.isPressed ? 0.97 : 1.0
    }
}

extension ButtonStyle where Self == CardPressStyle {
    static var card: CardPressStyle { CardPressStyle() }
}
