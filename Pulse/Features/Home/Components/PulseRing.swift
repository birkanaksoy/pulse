import SwiftUI

struct PulseRing: View {
    var score: Int
    var isScanning: Bool = false
    var size: CGFloat = 280

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedScore: Double = 0
    @State private var breathing: Bool = false
    @State private var scanRotation: Double = 0

    var body: some View {
        let status = PulseStatus(score: score)
        let progress = animatedScore / 100.0

        ZStack {
            // Outer ambient glow tinted by status.
            Circle()
                .fill(status.color.opacity(0.12))
                .blur(radius: 40)
                .scaleEffect(breathing ? 1.08 : 1.0)

            // Background track — fine, low contrast.
            Circle()
                .stroke(PulseColor.stroke, lineWidth: 6)
                .padding(20)

            // Mid-ring shadow tray so progress pops.
            Circle()
                .stroke(PulseColor.stroke.opacity(0.55), lineWidth: 18)
                .padding(8)

            // Score progress — the hero.
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient(for: status),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .padding(8)
                .rotationEffect(.degrees(-90))
                .shadow(color: status.color.opacity(0.35), radius: 16, y: 6)

            // Scanning sweep — overlays a rotating dot at the head.
            if isScanning && !reduceMotion {
                Circle()
                    .trim(from: 0, to: 0.001)
                    .stroke(.white, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .padding(8)
                    .rotationEffect(.degrees(scanRotation - 90))
                    .opacity(0.9)
                    .shadow(color: .white.opacity(0.5), radius: 8)
            }

            // Centre stack — number, label, status pill.
            VStack(spacing: 6) {
                Text("\(Int(animatedScore))")
                    .font(.system(size: 76, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [PulseColor.textPrimary, PulseColor.textPrimary.opacity(0.78)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText(value: animatedScore))
                    .monospacedDigit()
                Text("PULSE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(PulseColor.textTertiary)
                statusPill(status)
                    .padding(.top, 4)
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

    // MARK: - Sub-views

    private func statusPill(_ status: PulseStatus) -> some View {
        Text(status.label)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(status.color.opacity(0.12))
            )
            .overlay(
                Capsule().strokeBorder(status.color.opacity(0.25), lineWidth: 1)
            )
    }

    // MARK: - Status-tinted gradient

    private func progressGradient(for status: PulseStatus) -> AngularGradient {
        let colors: [Color] = {
            switch status {
            case .excellent: return [PulseColor.blue500, PulseColor.blue300, PulseColor.excellent]
            case .good:      return [PulseColor.blue500, PulseColor.blue300]
            case .fair:      return [PulseColor.blue500, PulseColor.fair]
            case .critical:  return [PulseColor.critical, PulseColor.fair]
            }
        }()
        return AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    // MARK: - Animation

    private func startAnimations(score: Int) {
        if reduceMotion {
            animatedScore = Double(score)
        } else {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.78)) {
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
            withAnimation(.spring(response: 1.0, dampingFraction: 0.78)) {
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
        PulseRing(score: 35, isScanning: true)
    }
    .padding()
    .background(PulseColor.muted)
}
