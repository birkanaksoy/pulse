import SwiftUI
import SwiftData

private let blue500 = Color(red: 0.184, green: 0.420, blue: 1.000)
private let blue300 = Color(red: 0.431, green: 0.765, blue: 1.000)
private let excellent = Color(red: 0.129, green: 0.753, blue: 0.478)
private let fair = Color(red: 0.961, green: 0.647, blue: 0.141)
private let critical = Color(red: 0.937, green: 0.267, blue: 0.267)

struct WatchHomeView: View {
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    private var latest: ScanRecord? { records.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ringSection
                stats
            }
            .padding(.vertical, 8)
        }
        .containerBackground(
            LinearGradient(
                colors: [Color.black, statusColor.opacity(0.25)],
                startPoint: .top, endPoint: .bottom
            ),
            for: .navigation
        )
    }

    @ViewBuilder
    private var ringSection: some View {
        if let r = latest {
            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: Double(r.pulseScore) / 100.0)
                    .stroke(
                        AngularGradient(
                            colors: [blue500, blue300, statusColor],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(r.pulseScore)")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(statusLabel(r.pulseScore))
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                }
            }
            .frame(width: 130, height: 130)
        } else {
            VStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(blue500)
                Text("No scan yet")
                    .font(.footnote)
                Text("Open Pulse on iPhone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
        }
    }

    @ViewBuilder
    private var stats: some View {
        if let r = latest {
            VStack(spacing: 6) {
                row(icon: "internaldrive", title: "Storage", value: "\(r.storageUsed)%")
                row(icon: thermalIcon(r.thermalRaw), title: "Thermal", value: thermalLabel(r.thermalRaw))
                if let lvl = r.batteryLevel {
                    row(icon: "battery.75percent", title: "Battery", value: "\(lvl)%")
                }
                Text(r.timestamp, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private func row(icon: String, title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(blue500).frame(width: 16)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).monospacedDigit()
        }
    }

    private var statusColor: Color {
        guard let r = latest else { return blue500 }
        switch r.pulseScore {
        case 85...: return excellent
        case 65...: return blue500
        case 40...: return fair
        default:    return critical
        }
    }

    private func statusLabel(_ score: Int) -> String {
        switch score {
        case 85...: return String(localized: "Excellent")
        case 65...: return String(localized: "Good")
        case 40...: return String(localized: "Fair")
        default:    return String(localized: "Critical")
        }
    }
    private func thermalLabel(_ raw: Int) -> String {
        switch raw {
        case 0: return String(localized: "Normal")
        case 1: return String(localized: "Fair")
        case 2: return String(localized: "Warm")
        default: return String(localized: "Hot")
        }
    }
    private func thermalIcon(_ raw: Int) -> String {
        switch raw {
        case 0: return "thermometer.low"
        case 1: return "thermometer.medium"
        case 2: return "thermometer.high"
        default: return "thermometer.sun.fill"
        }
    }
}
