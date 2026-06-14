import SwiftUI

struct MetricCard: View {
    var icon: String
    var title: String
    var value: String
    var status: String
    var statusColor: Color
    var isScanning: Bool = false
    var sparkline: [Double] = []

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Sparkline ghost behind the content
            if sparkline.count >= 2 {
                MiniSparkline(values: sparkline, tint: statusColor)
                    .frame(height: 42)
                    .padding(.trailing, -8)
                    .padding(.bottom, -4)
                    .opacity(0.5)
                    .allowsHitTesting(false)
            }

            VStack(alignment: .leading, spacing: PulseSpace.m) {
                HStack(alignment: .top) {
                    iconChip
                    Spacer()
                    statusDot
                }
                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(PulseColor.textPrimary)
                    .monospacedDigit()
                    .kerning(-0.8)
                    .redacted(reason: isScanning ? .placeholder : [])
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PulseColor.textSecondary)
                    Text(status)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(PulseColor.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .pulseCard(padding: PulseSpace.l)
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
            .frame(width: 38, height: 38)
            .background(
                LinearGradient(
                    colors: [PulseColor.blue500, PulseColor.blue300],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            )
            .shadow(color: PulseColor.blue500.opacity(0.4), radius: 8, y: 4)
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: statusColor.opacity(0.6), radius: 5)
    }
}

struct MiniSparkline: View {
    var values: [Double]
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let step = values.count > 1 ? w / CGFloat(values.count - 1) : 0

            ZStack {
                // Filled area underneath
                Path { p in
                    p.move(to: .init(x: 0, y: h))
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) * step
                        let y = h - (CGFloat(max(0, min(1, v))) * h)
                        p.addLine(to: .init(x: x, y: y))
                    }
                    p.addLine(to: .init(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.3), tint.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                // Line
                Path { p in
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) * step
                        let y = h - (CGFloat(max(0, min(1, v))) * h)
                        if i == 0 { p.move(to: .init(x: x, y: y)) }
                        else      { p.addLine(to: .init(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.7), tint],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
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
