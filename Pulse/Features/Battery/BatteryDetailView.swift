import SwiftUI
import SwiftData
import UIKit

struct BatteryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    @State private var level: Int = 0
    @State private var state: UIDevice.BatteryState = .unknown
    @State private var lowPowerMode = false
    @State private var levelKnown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                hero
                healthDeepLinkCard
                history
                disclaimer
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.l)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(PulseColor.muted.ignoresSafeArea())
        .navigationTitle("Battery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSProcessInfoPowerStateDidChange)) { _ in refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Battery")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pulse shows only what iOS exposes publicly — current state, not fabricated metrics.")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
        }
    }

    private var hero: some View {
        HStack(spacing: PulseSpace.l) {
            ZStack {
                Circle().stroke(PulseColor.stroke, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: Double(level) / 100.0)
                    .stroke(PulseColor.ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(levelKnown ? "\(level)%" : "—")
                        .font(PulseFont.titleL)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Charge")
                        .font(PulseFont.footnote)
                        .foregroundStyle(PulseColor.textTertiary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: PulseSpace.s) {
                kv("State", stateLabel)
                kv("Low Power Mode", lowPowerMode ? "On" : "Off")
                if !levelKnown {
                    Text("Battery level unavailable (running on Simulator)")
                        .font(PulseFont.footnote)
                        .foregroundStyle(PulseColor.fair)
                }
            }
            Spacer()
        }
        .pulseCard()
    }

    private var healthDeepLinkCard: some View {
        Button {
            if let url = URL(string: "App-Prefs:Battery"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PulseColor.blue500)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(PulseColor.blue50))
                VStack(alignment: .leading, spacing: 2) {
                    Text("See Battery Health")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("iOS keeps the real maximum capacity in Settings.")
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.plain)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Charge over recent scans")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            let values = records.prefix(14).reversed().compactMap { $0.batteryLevel }
            if values.count < 2 {
                Text("Run more scans to build a trend.")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                MiniBars(values: Array(values))
                    .frame(height: 80)
            }
        }
        .pulseCard()
    }

    private var disclaimer: some View {
        Text("iOS does not expose true battery health to apps. Anything claiming a precise health % from a third-party app is guessing.")
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)
            .padding(.horizontal, PulseSpace.s)
    }

    private func refresh() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let raw = UIDevice.current.batteryLevel
        levelKnown = raw >= 0
        level = levelKnown ? Int((raw * 100).rounded()) : 0
        state = UIDevice.current.batteryState
        lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private var stateLabel: String {
        switch state {
        case .charging:  return "Charging"
        case .full:      return "Full"
        case .unplugged: return "Unplugged"
        default:         return "Unknown"
        }
    }

    private func kv(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(k).font(PulseFont.footnote).foregroundStyle(PulseColor.textTertiary)
            Text(v).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
        }
    }
}

struct MiniBars: View {
    var values: [Int]
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(PulseColor.ringGradient)
                        .frame(height: max(6, geo.size.height * CGFloat(v) / 100))
                }
            }
        }
    }
}
