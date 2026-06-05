import SwiftUI
import SwiftData

struct TemperatureDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    @State private var current: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                hero
                weekStats
                causes
                disclaimer
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.l)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(PulseColor.muted.ignoresSafeArea())
        .navigationTitle("Temperature")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .onAppear { current = ProcessInfo.processInfo.thermalState }
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)) { _ in
            current = ProcessInfo.processInfo.thermalState
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Temperature")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Thermal state is reported directly by iOS.")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
        }
    }

    private var hero: some View {
        HStack(spacing: PulseSpace.l) {
            ZStack {
                Circle().fill(currentColor.opacity(0.12))
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(currentColor)
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text(currentLabel)
                    .font(PulseFont.titleL)
                    .foregroundStyle(PulseColor.textPrimary)
                Text(currentSubtitle)
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
        }
        .pulseCard()
    }

    private var weekStats: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Past 7 days")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            VStack(spacing: 0) {
                stat("Scans logged", "\(week.count)")
                Divider().background(PulseColor.stroke)
                stat("Normal",  "\(count(of: 0))", color: PulseColor.excellent)
                Divider().background(PulseColor.stroke)
                stat("Fair",    "\(count(of: 1))", color: PulseColor.good)
                Divider().background(PulseColor.stroke)
                stat("Warm",    "\(count(of: 2))", color: PulseColor.fair)
                Divider().background(PulseColor.stroke)
                stat("Hot",     "\(count(of: 3))", color: PulseColor.critical)
            }
        }
        .pulseCard()
    }

    private var causes: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Common causes")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            cause("sun.max.fill",     "Direct sunlight or hot environment")
            cause("camera.fill",      "Long camera, AR or video sessions")
            cause("bolt.fill",        "Charging while gaming or streaming")
            cause("antenna.radiowaves.left.and.right", "Poor cellular signal forcing the radio")
        }
        .pulseCard()
    }

    private var disclaimer: some View {
        Text("iOS does not expose precise °C/°F. Pulse shows the same coarse thermal state iOS uses to throttle performance.")
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)
            .padding(.horizontal, PulseSpace.s)
    }

    // MARK: - Derived

    private var currentLabel: String {
        switch current {
        case .nominal:  return "Normal"
        case .fair:     return "Fair"
        case .serious:  return "Warm"
        case .critical: return "Hot"
        @unknown default: return "Unknown"
        }
    }
    private var currentSubtitle: String {
        switch current {
        case .nominal:  return "Running cool."
        case .fair:     return "Slightly elevated, normal."
        case .serious:  return "iOS may throttle performance."
        case .critical: return "Move to a cooler spot if possible."
        @unknown default: return "—"
        }
    }
    private var currentColor: Color {
        switch current {
        case .nominal:  return PulseColor.excellent
        case .fair:     return PulseColor.good
        case .serious:  return PulseColor.fair
        case .critical: return PulseColor.critical
        @unknown default: return PulseColor.textTertiary
        }
    }
    private var week: [ScanRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return records.filter { $0.timestamp >= cutoff }
    }
    private func count(of raw: Int) -> Int { week.filter { $0.thermalRaw == raw }.count }

    private func stat(_ k: String, _ v: String, color: Color? = nil) -> some View {
        HStack {
            if let c = color {
                Circle().fill(c).frame(width: 8, height: 8)
            }
            Text(k).font(PulseFont.body).foregroundStyle(PulseColor.textSecondary)
            Spacer()
            Text(v).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
        }
        .padding(.vertical, PulseSpace.m)
    }

    private func cause(_ icon: String, _ text: String) -> some View {
        HStack(spacing: PulseSpace.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PulseColor.blue500)
                .frame(width: 28)
            Text(text)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textPrimary)
            Spacer()
        }
    }
}
