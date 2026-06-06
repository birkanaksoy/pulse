import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(EntitlementStore.self) private var entitlements
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]
    var engine: ScanEngine
    @State private var presentedDetail: Detail?

    enum Detail: String, Identifiable {
        case battery, storage, temperature
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseStatus(score: score).color)
            ScrollView {
                VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                    header
                    ringSection
                    metricsGrid
                    scanButton
                    insightsSection
                }
                .padding(.horizontal, PulseSpace.xl)
                .padding(.top, PulseSpace.l)
                .padding(.bottom, PulseSpace.xxxl)
            }
            .scrollContentBackground(.hidden)
        }
        .refreshable {
            await engine.runFullScan()
            persistLatest()
        }
        .sheet(item: $presentedDetail) { detail in
            NavigationStack {
                switch detail {
                case .battery:     BatteryDetailView()
                case .storage:     StorageDetailView()
                case .temperature: TemperatureDetailView()
                }
            }
            .pulseSheet()
        }
        // No auto-scan: respect the empty state. User triggers via the
        // primary button or pull-to-refresh.
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textTertiary)
            Text("Your Pulse")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
        }
    }

    private var ringSection: some View {
        VStack(spacing: PulseSpace.s) {
            if engine.lastResult == nil && !isScanning {
                emptyRing
            } else {
                PulseRing(score: score, isScanning: isScanning)
                Text(lastScanLabel)
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyRing: some View {
        EmptyRingState()
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: PulseSpace.l),
                      GridItem(.flexible(), spacing: PulseSpace.l)],
            spacing: PulseSpace.l
        ) {
            tappableCard(.storage) {
                MetricCard(
                    icon: "internaldrive",
                    title: "Storage",
                    value: "\(engine.lastResult?.storage.usedPercent ?? 0)%",
                    status: "Used",
                    statusColor: storageColor,
                    isScanning: isScanning,
                    sparkline: storageSparkline
                )
            }
            tappableCard(.temperature) {
                MetricCard(
                    icon: "thermometer.medium",
                    title: "Temperature",
                    value: engine.lastResult?.thermal.label ?? "—",
                    status: "System thermal",
                    statusColor: thermalColor,
                    isScanning: isScanning
                )
            }
            tappableCard(.battery) {
                MetricCard(
                    icon: batteryIcon,
                    title: "Battery",
                    value: batteryValue,
                    status: engine.lastResult?.battery.stateLabel ?? "—",
                    statusColor: PulseColor.good,
                    isScanning: isScanning,
                    sparkline: batterySparkline
                )
            }
            MetricCard(
                icon: "leaf",
                title: "Low Power",
                value: (engine.lastResult?.battery.isLowPowerMode ?? false) ? "On" : "Off",
                status: "iOS power saver",
                statusColor: (engine.lastResult?.battery.isLowPowerMode ?? false) ? PulseColor.fair : PulseColor.excellent,
                isScanning: isScanning
            )
        }
    }

    private var scanButton: some View {
        PrimaryButton(
            title: isScanning ? "Scanning…" : "Run Full Scan",
            systemImage: isScanning ? nil : "arrow.right",
            isLoading: isScanning
        ) {
            Task {
                await engine.runFullScan()
                persistLatest()
            }
        }
    }

    private var insightsSection: some View {
        let insights = InsightsGenerator.generate(latest: engine.lastResult, records: records)
        return Group {
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: PulseSpace.m) {
                    SectionHeader("Today's insights")

                    VStack(spacing: 0) {
                        ForEach(Array(insights.enumerated()), id: \.element.id) { idx, insight in
                            if idx > 0 { Divider().background(PulseColor.stroke) }
                            insightRow(insight)
                        }
                    }
                    .pulseCard()
                }
            }
        }
    }

    private func insightRow(_ insight: LiveInsight) -> some View {
        HStack(spacing: PulseSpace.m) {
            Image(systemName: insight.icon)
                .foregroundStyle(PulseColor.blue500)
                .frame(width: 24)
            Text(insight.text)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textPrimary)
            Spacer()
        }
        .padding(.vertical, PulseSpace.m)
    }

    // MARK: - Derived

    private var score: Int { engine.lastResult?.pulseScore ?? 0 }

    private var isScanning: Bool {
        if case .scanning = engine.phase { return true }
        return false
    }

    private var lastScanLabel: String {
        guard let ts = engine.lastResult?.timestamp else {
            return String(localized: "No scan yet")
        }
        let elapsed = Date().timeIntervalSince(ts)
        let relative: String
        if elapsed < 60 {
            relative = String(localized: "just now")
        } else {
            let f = RelativeDateTimeFormatter()
            f.locale = .current
            f.unitsStyle = .short
            relative = f.localizedString(for: ts, relativeTo: Date())
        }
        return String(localized: "Last scan · \(relative)")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return String(localized: "Good morning")
        case 12..<18: return String(localized: "Good afternoon")
        default:      return String(localized: "Good evening")
        }
    }

    private var storageColor: Color {
        let p = engine.lastResult?.storage.usedPercent ?? 0
        switch p {
        case ..<60:  return PulseColor.excellent
        case ..<80:  return PulseColor.good
        case ..<90:  return PulseColor.fair
        default:     return PulseColor.critical
        }
    }

    @ViewBuilder
    private func tappableCard<C: View>(_ detail: Detail, @ViewBuilder _ content: () -> C) -> some View {
        Button {
            presentedDetail = detail
        } label: {
            content()
        }
        .buttonStyle(.card)
    }

    private var storageSparkline: [Double] {
        records.prefix(12).reversed().map { Double($0.storageUsed) / 100.0 }
    }
    private var batterySparkline: [Double] {
        records.prefix(12).reversed().compactMap { $0.batteryLevel.map { Double($0) / 100.0 } }
    }

    private var batteryValue: String {
        guard let b = engine.lastResult?.battery else { return "—" }
        return b.levelKnown ? "\(b.levelPercent)%" : "—"
    }
    private var batteryIcon: String {
        guard let b = engine.lastResult?.battery, b.levelKnown else { return "battery.0percent" }
        switch b.levelPercent {
        case 90...:  return "battery.100percent"
        case 65...:  return "battery.75percent"
        case 35...:  return "battery.50percent"
        case 15...:  return "battery.25percent"
        default:     return "battery.0percent"
        }
    }

    private var thermalColor: Color {
        switch engine.lastResult?.thermal.state {
        case .nominal: return PulseColor.excellent
        case .fair:    return PulseColor.good
        case .serious: return PulseColor.fair
        case .critical: return PulseColor.critical
        default:       return PulseColor.textTertiary
        }
    }

    private func purgeOldRecords() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate<ScanRecord> { $0.timestamp < cutoff }
        )
        if let old = try? context.fetch(descriptor) {
            for r in old { context.delete(r) }
        }
    }

    private func persistLatest() {
        guard let r = engine.lastResult else { return }
        purgeOldRecords()
        // Rate-limit: don't insert a new record if the previous one is < 60s old.
        let recent = try? context.fetch(
            FetchDescriptor<ScanRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        ).first
        if let last = recent, r.timestamp.timeIntervalSince(last.timestamp) < 60 {
            // Update the existing record so the trend still reflects the latest scan.
            last.pulseScore = r.pulseScore
            last.storageUsed = r.storage.usedPercent
            try? context.save()
            SharedScoreStore.save(.init(
                score: r.pulseScore,
                status: PulseStatus(score: r.pulseScore).label,
                timestamp: r.timestamp
            ))
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        context.insert(ScanRecord.from(r))
        try? context.save()
        SharedScoreStore.save(.init(
            score: r.pulseScore,
            status: PulseStatus(score: r.pulseScore).label,
            timestamp: r.timestamp,
            isPro: entitlements.isPro
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview { HomeView(engine: ScanEngine()) }
