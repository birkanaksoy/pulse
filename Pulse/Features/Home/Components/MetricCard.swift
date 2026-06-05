import SwiftUI

struct MetricCard: View {
    var icon: String
    var title: String
    var value: String
    var status: String
    var statusColor: Color
    var isScanning: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PulseColor.blue500)
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            Text(value)
                .font(PulseFont.titleL)
                .foregroundStyle(PulseColor.textPrimary)
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
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PulseSpace.l) {
        MetricCard(icon: "battery.75percent", title: "Battery", value: "89%", status: "Healthy", statusColor: PulseColor.excellent)
        MetricCard(icon: "internaldrive", title: "Storage", value: "64%", status: "Some clutter", statusColor: PulseColor.fair)
        MetricCard(icon: "bolt.fill", title: "Performance", value: "Good", status: "Smooth", statusColor: PulseColor.good, isScanning: true)
        MetricCard(icon: "thermometer.medium", title: "Temperature", value: "34°", status: "Normal", statusColor: PulseColor.excellent)
    }
    .padding()
    .background(PulseColor.muted)
}
