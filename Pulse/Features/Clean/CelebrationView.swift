import SwiftUI

/// 32 confetti particles bursting from centre, drifting downward.
/// Pure SwiftUI, no external dependencies.
struct ConfettiBurst: View {
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let particles: [Particle] = (0..<32).map { _ in Particle.random() }

    var body: some View {
        ZStack {
            ForEach(0..<particles.count, id: \.self) { i in
                let p = particles[i]
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(p.color)
                    .frame(width: 8, height: 14)
                    .rotationEffect(.degrees(animate ? p.endRotation : p.startRotation))
                    .offset(
                        x: animate ? p.endX : 0,
                        y: animate ? p.endY : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        reduceMotion ? nil :
                            .interpolatingSpring(stiffness: 30, damping: 7).delay(p.delay),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }

    private struct Particle {
        var endX: CGFloat
        var endY: CGFloat
        var startRotation: Double
        var endRotation: Double
        var color: Color
        var delay: Double

        static func random() -> Particle {
            let angle = Double.random(in: 0..<(2 * .pi))
            let radius = Double.random(in: 120...260)
            let colors: [Color] = [
                PulseColor.blue500, PulseColor.blue300,
                PulseColor.excellent, PulseColor.fair,
                PulseColor.purple, PulseColor.teal
            ]
            return Particle(
                endX: CGFloat(cos(angle) * radius),
                endY: CGFloat(sin(angle) * radius) + 200, // drift down
                startRotation: Double.random(in: -45...45),
                endRotation: Double.random(in: -540...540),
                color: colors.randomElement() ?? PulseColor.blue500,
                delay: Double.random(in: 0...0.15)
            )
        }
    }
}
