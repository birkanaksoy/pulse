import SwiftUI

struct MetricCard: View {
    var icon: String
    var title: String
    var value: String
    var status: String
    var statusColor: Color
    var isScanning: Bool = false
    /// Optional 0..1 normalised values for a tiny background sparkline.
    var sparkline: [Double] = []

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Sparkline ghost behind the content
            if sparkline.count >= 2 {
                MiniSparkline(values: sparkline, tint: statusColor)
                    .frame(height: 36)
                    .padding(.trailing, -6)
                    .padding(.bottom, -2)
                    .opacity(0.55)
                    .allowsHitTesting(false)
            }

            VStack(alignment: .leading, spacing: PulseSpace.m) {
                HStack(alignment: .top) {
                    iconChip
                    Spacer()
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor.opacity(0.45), radius: 4)
                }
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(PulseColor.textPrimary)
                    .monospacedDigit()
                    .redacted(reason: isScanning ? .placeholder : [])
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                    Text(status)
                        .font(PulseFont.footnote)
                        .foregroundStyle(PulseColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .pulseCard()
        .overlay(
            RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                .stroke(PulseColor.blue500.opacity(isScanning ? 0.4 : 0), lineWidth: 1.5)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isScanning)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(value), \(status)"))
    }

    private var iconChip: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(
                LinearGradient(
                    colors: [PulseColor.blue500, PulseColor.blue300],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(color: PulseColor.blue500.opacity(0.35), radius: 8, y: 4)
    }
}

/// Inline mini chart — 0..1 normalised values rendered as a small line.
struct MiniSparkline: View {
    var values: [Double]
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let step = values.count > 1 ? w / CGFloat(values.count - 1) : 0

            Path { p in
                for (i, v) in values.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h - (CGFloat(max(0, min(1, v))) * h)
                    if i == 0 { p.move(to: .init(x: x, y: y)) }
                    else      { p.addLine(to: .init(x: x, y: y)) }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [tint.opacity(0.6), tint],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PulseSpace.l) {
        MetricCard(icon: "internaldrive", title: "Storage", value: "64%",
                   status: "Used", statusColor: PulseColor.good,
                   sparkline: [0.4, 0.5, 0.55, 0.6, 0.62, 0.64])
        MetricCard(icon: "thermometer.medium", title: "Temperature", value: "Normal",
                   status: "System thermal", statusColor: PulseColor.excellent)
        MetricCard(icon: "battery.75percent", title: "Battery", value: "89%",
                   status: "Charging", statusColor: PulseColor.good, isScanning: true)
        MetricCard(icon: "leaf", title: "Low Power", value: "Off",
                   status: "iOS power saver", statusColor: PulseColor.excellent)
    }
    .padding()
    .background(PulseColor.muted)
}
