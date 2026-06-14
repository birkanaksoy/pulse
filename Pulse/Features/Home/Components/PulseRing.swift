import SwiftUI

struct PulseRing: View {
    var score: Int
    var isScanning: Bool = false
    var size: CGFloat = 280

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedScore: Double = 0
    @State private var breathing = false
    @State private var scanRotation: Double = 0
    @State private var sparkleAngle: Double = 0

    var body: some View {
        let status = PulseStatus(score: score)
        let progress = animatedScore / 100.0

        ZStack {
            // Outer halo — wide, soft, status-tinted
            Circle()
                .fill(
                    RadialGradient(
                        colors: [status.color.opacity(0.30), status.color.opacity(0)],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.65
                    )
                )
                .blur(radius: 24)
                .scaleEffect(breathing ? 1.10 : 1.0)

            // Subtle outer ring of dots for premium texture
            ForEach(0..<48, id: \.self) { i in
                Circle()
                    .fill(status.color.opacity(0.10))
                    .frame(width: 3, height: 3)
                    .offset(y: -size / 2 + 4)
                    .rotationEffect(.degrees(Double(i) * 7.5))
            }
            .opacity(breathing ? 0.7 : 0.4)

            // Track
            Circle()
                .stroke(PulseColor.stroke, lineWidth: 6)
                .padding(20)

            // Inner shadow tray
            Circle()
                .stroke(PulseColor.strokeStrong.opacity(0.55), lineWidth: 20)
                .padding(8)

            // Progress arc — status gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    status.gradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .padding(8)
                .rotationEffect(.degrees(-90))
                .shadow(color: status.color.opacity(0.40), radius: 14, y: 6)

            // Sparkle dot at progress head
            if progress > 0 {
                Circle()
                    .fill(.white)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(status.color, lineWidth: 3))
                    .offset(y: -(size / 2 - 18))
                    .rotationEffect(.degrees(progress * 360))
                    .shadow(color: status.color.opacity(0.6), radius: 6)
                    .opacity(isScanning ? 0 : 1)
            }

            // Scanning sweep
            if isScanning && !reduceMotion {
                Circle()
                    .trim(from: 0, to: 0.001)
                    .stroke(.white, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .padding(8)
                    .rotationEffect(.degrees(scanRotation - 90))
                    .opacity(0.9)
                    .shadow(color: .white.opacity(0.5), radius: 8)
            }

            // Centre stack
            VStack(spacing: 4) {
                Text("\(Int(animatedScore))")
                    .font(.system(size: 84, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [PulseColor.textPrimary, PulseColor.textPrimary.opacity(0.7)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText(value: animatedScore))
                    .monospacedDigit()
                    .kerning(-2)
                Text("PULSE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(PulseColor.textTertiary)
                Text(status.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(status.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(status.color.opacity(0.14))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(status.color.opacity(0.28), lineWidth: 0.5)
                    )
                    .padding(.top, 6)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Pulse score"))
        .accessibilityValue(Text("\(score), \(status.label)"))
        .accessibilityAddTraits(isScanning ? .updatesFrequently : [])
        .onAppear { startAnimations(score: score) }
        .onChange(of: score) { _, new in animateToScore(new) }
        .onChange(of: isScanning) { _, scanning in updateScanningState(scanning) }
    }

    // MARK: - Animation

    private func startAnimations(score: Int) {
        if reduceMotion {
            animatedScore = Double(score)
        } else {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.78)) {
                animatedScore = Double(score)
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        if isScanning { startScanRotation() }
    }

    private func animateToScore(_ new: Int) {
        if reduceMotion {
            animatedScore = Double(new)
        } else {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.78)) {
                animatedScore = Double(new)
            }
        }
    }

    private func updateScanningState(_ scanning: Bool) {
        if scanning && !reduceMotion {
            startScanRotation()
        } else {
            withAnimation(.easeOut(duration: 0.2)) { scanRotation = 0 }
        }
    }

    private func startScanRotation() {
        scanRotation = 0
        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
            scanRotation = 360
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PulseRing(score: 92)
        PulseRing(score: 35, isScanning: true, size: 200)
    }
    .padding()
    .background(PulseColor.muted)
}
