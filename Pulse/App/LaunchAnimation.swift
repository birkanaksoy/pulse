import SwiftUI

/// Small splash animation shown briefly on every cold launch.
/// 1.4 seconds total: ring draws + pulse + fades out.
struct LaunchAnimation<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var showSplash = true
    @State private var ringProgress: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.7
    @State private var iconOpacity: Double = 0
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

            // Soft glow behind logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [PulseColor.blue500.opacity(0.25), .clear],
                        center: .center, startRadius: 0, endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .opacity(glowOpacity)
                .blur(radius: 18)

            // Outer ring drawing animation
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [PulseColor.blue500, PulseColor.purple, PulseColor.teal, PulseColor.blue500],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: 140)

            // ECG glyph in center
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [PulseColor.blue500, PulseColor.blue300],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .shadow(color: PulseColor.blue500.opacity(0.35), radius: 14, y: 4)
        }
    }

    @MainActor
    private func run() async {
        guard showSplash else { return }
        if reduceMotion {
            ringProgress = 1; iconScale = 1; iconOpacity = 1; glowOpacity = 1
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeOut(duration: 0.35)) { showSplash = false }
            return
        }

        withAnimation(.easeOut(duration: 0.4)) {
            iconScale = 1.0
            iconOpacity = 1.0
            glowOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.8)) {
            ringProgress = 1.0
        }
        try? await Task.sleep(nanoseconds: 900_000_000)
        withAnimation(.easeInOut(duration: 0.25)) {
            iconScale = 0.92
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            showSplash = false
        }
    }
}
