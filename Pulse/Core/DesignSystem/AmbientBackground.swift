import SwiftUI

/// Premium ambient backdrop: muted base + 4 soft radial gradients overlaid,
/// rasterized for perf. Looks great behind hero sections; subtle enough to
/// never compete with content.
struct AmbientBackground: View {
    var tint: Color = PulseColor.blue500

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let baseOpacity = scheme == .dark ? 1.0 : 1.0

            ZStack {
                PulseColor.muted

                if !reduceTransparency {
                    blob(color: tint, radius: w * 0.85,
                         position: CGPoint(x: w * 0.20, y: h * 0.18),
                         opacity: scheme == .dark ? 0.32 : 0.20)
                    blob(color: PulseColor.purple, radius: w * 0.7,
                         position: CGPoint(x: w * 0.92, y: h * 0.08),
                         opacity: scheme == .dark ? 0.18 : 0.10)
                    blob(color: PulseColor.blue300, radius: w * 0.80,
                         position: CGPoint(x: w * 0.85, y: h * 0.55),
                         opacity: scheme == .dark ? 0.20 : 0.13)
                    blob(color: tint.opacity(0.7), radius: w * 0.95,
                         position: CGPoint(x: w * 0.30, y: h * 0.85),
                         opacity: scheme == .dark ? 0.20 : 0.10)
                }
            }
            .opacity(baseOpacity)
            .compositingGroup()
            .drawingGroup()
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
            .blur(radius: 28)
    }
}
