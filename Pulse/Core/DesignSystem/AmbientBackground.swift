import SwiftUI

/// Soft, premium ambient backdrop made of overlapping radial gradients.
/// Looks great behind hero sections; subtle enough to never compete with content.
struct AmbientBackground: View {
    /// The dominant tint — usually the current status color.
    var tint: Color = PulseColor.blue500

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                PulseColor.muted

                blob(
                    color: tint,
                    radius: w * 0.85,
                    position: CGPoint(x: w * 0.25, y: h * 0.20),
                    opacity: scheme == .dark ? 0.30 : 0.18
                )
                blob(
                    color: PulseColor.blue300,
                    radius: w * 0.75,
                    position: CGPoint(x: w * 0.85, y: h * 0.10),
                    opacity: scheme == .dark ? 0.22 : 0.14
                )
                blob(
                    color: tint.opacity(0.8),
                    radius: w * 0.95,
                    position: CGPoint(x: w * 0.55, y: h * 0.55),
                    opacity: scheme == .dark ? 0.20 : 0.10
                )
            }
            .compositingGroup()
            .drawingGroup()         // rasterise for perf
        }
        .ignoresSafeArea()
    }

    private func blob(color: Color, radius: CGFloat, position: CGPoint, opacity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(position)
            .blur(radius: 30)
    }
}
