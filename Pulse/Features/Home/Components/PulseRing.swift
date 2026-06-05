import SwiftUI

struct PulseRing: View {
    var score: Int
    var isScanning: Bool = false
    var size: CGFloat = 260

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedScore: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        let status = PulseStatus(score: score)
        let progress = animatedScore / 100.0

        ZStack {
            Circle()
                .stroke(PulseColor.stroke, lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    PulseColor.ringGradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: PulseColor.blue500.opacity(0.25), radius: 12, y: 4)

            VStack(spacing: 4) {
                Text("\(Int(animatedScore))")
                    .font(PulseFont.hero)
                    .foregroundStyle(PulseColor.textPrimary)
                    .contentTransition(.numericText(value: animatedScore))
                Text("Pulse")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textTertiary)
                Text(status.label)
                    .font(PulseFont.callout)
                    .foregroundStyle(status.color)
                    .padding(.top, 2)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(pulse ? 1.015 : 1.0)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
            value: pulse
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Pulse score"))
        .accessibilityValue(Text("\(score), \(status.label)"))
        .accessibilityAddTraits(isScanning ? .updatesFrequently : [])
        .onAppear {
            if reduceMotion {
                animatedScore = Double(score)
            } else {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                    animatedScore = Double(score)
                }
            }
            if isScanning && !reduceMotion { pulse = true }
        }
        .onChange(of: score) { _, new in
            if reduceMotion {
                animatedScore = Double(new)
            } else {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                    animatedScore = Double(new)
                }
            }
        }
        .onChange(of: isScanning) { _, scanning in
            pulse = scanning && !reduceMotion
        }
    }
}
