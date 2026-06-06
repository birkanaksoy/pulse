import SwiftUI

struct StreakBadge: View {
    var streak: StreakState

    var body: some View {
        if streak.current >= 2 {
            HStack(spacing: 6) {
                Text("🔥")
                Text("\(streak.current)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(streak.current == 1 ? "day" : "days")
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(PulseColor.fair.opacity(0.18))
            )
            .overlay(
                Capsule().strokeBorder(PulseColor.fair.opacity(0.3), lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(streak.current) day scan streak"))
        }
    }
}
