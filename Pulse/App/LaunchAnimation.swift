import SwiftUI

/// Brief splash on every cold launch: the Pulse logo appears in the centre,
/// a gradient ring sweeps around it, then everything fades out.
struct LaunchAnimation<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var showSplash = true
    @State private var ringProgress: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            content()
                .opacity(showSplash ? 0 : 1)
                .scaleEffect(showSplash ? 1.02 : 1)
                .animation(.easeOut(duration: 0.5), value: showSplash)

            if showSplash {
                splash
                    .transition(.opacity)
            }
        }
        .task { await run() }
    }

    private var splash: some View {
        ZStack {
            PulseColor.canvas.ignoresSafeArea()

            // Soft glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [PulseColor.blue500.opacity(0.25), .clear],
                        center: .center, startRadius: 0, endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .opacity(glowOpacity)
                .blur(radius: 22)

            // Animated brand ring around the logo
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [PulseColor.blue500, PulseColor.purple, PulseColor.teal, PulseColor.blue500],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 168, height: 168)

            // The app icon itself
            PulseLogo(size: 132, shadow: true)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
    }

    @MainActor
    private func run() async {
        guard showSplash else { return }
        if reduceMotion {
            ringProgress = 1; logoScale = 1; logoOpacity = 1; glowOpacity = 1
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            logoScale = 1.0
            logoOpacity = 1.0
            glowOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.9).delay(0.1)) {
            ringProgress = 1.0
        }
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        withAnimation(.easeInOut(duration: 0.22)) {
            logoScale = 0.94
        }
        try? await Task.sleep(nanoseconds: 160_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            showSplash = false
        }
    }
}
