import SwiftUI

struct EmptyRingState: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    @State private var iconScale: CGFloat = 0.92

    var body: some View {
        VStack(spacing: PulseSpace.m) {
            ZStack {
                // Ambient glow that pulses with the ring.
                Circle()
                    .fill(PulseColor.blue500.opacity(glowOpacity * 0.18))
                    .blur(radius: 32)
                    .frame(width: 280, height: 280)

                // Dashed outline ring
                Circle()
                    .stroke(
                        PulseColor.blue500.opacity(0.35),
                        style: StrokeStyle(lineWidth: 2, dash: [4, 8])
                    )
                    .frame(width: 280, height: 280)

                // Inner solid track
                Circle()
                    .stroke(PulseColor.stroke, lineWidth: 14)
                    .frame(width: 260, height: 260)

                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [PulseColor.blue500, PulseColor.blue300],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                    Text("Ready to scan")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                }
            }
            .scaleEffect(ringScale)
            Text("Tap the button below to start.")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                ringScale = 1.025
                glowOpacity = 1.0
                iconScale = 1.0
            }
        }
    }
}
