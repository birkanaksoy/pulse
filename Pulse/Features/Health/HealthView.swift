import SwiftUI
import SwiftData

struct HealthView: View {
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var allRecords: [ScanRecord]
    @Environment(EntitlementStore.self) private var entitlements
    @State private var shareImage: UIImage?
    @State private var showingShare = false
    @State private var showingPaywall = false

    private var records: [ScanRecord] {
        HistoryFilter.visible(allRecords, isPro: entitlements.isPro)
    }
    private var isLimited: Bool {
        HistoryFilter.isLimited(allRecords, isPro: entitlements.isPro)
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            ScrollView {
                VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                    Text("Health")
                        .font(PulseFont.titleXL)
                        .foregroundStyle(PulseColor.textPrimary)
                    if allRecords.isEmpty {
                        emptyState
                    } else {
                        trendCard
                        statsCard
                        if isLimited { proHistoryHint }
                        WeeklyReportCard()
                        PersonalityCard(personality: personality, onShare: shareTapped)
                    }
                }
                .padding(.horizontal, PulseSpace.xl)
                .padding(.top, PulseSpace.l)
                .padding(.bottom, PulseSpace.xxxl)
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView().pulseSheet() }
        .sheet(isPresented: $showingShare) {
            if let img = shareImage {
                ShareSheet(items: [img])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: PulseSpace.l) {
            Spacer().frame(height: PulseSpace.xxxl)
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [PulseColor.blue500, PulseColor.blue300],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .padding(PulseSpace.xxl)
                .background(Circle().fill(PulseColor.blue50))
            Text("No scans yet")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Once you run a scan from Home, your trend, stats, and weekly report will appear here.")
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulseSpace.l)
            Spacer().frame(height: PulseSpace.xxxl)
        }
        .frame(maxWidth: .infinity)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            SectionHeader("Pulse Score · 7 days", trailing: AnyView(
                Text("Avg \(avgScore)")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textTertiary)
            ))
            if recentWeek.isEmpty {
                EmptyTrendPlaceholder()
            } else {
                TrendChart(records: recentWeek)
            }
        }
        .pulseCard()
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow("Total scans",       value: "\(records.count)")
            Divider().background(PulseColor.stroke)
            statRow("Days tracked",      value: "\(daysTracked)")
            Divider().background(PulseColor.stroke)
            statRow("Best day",          value: bestDay)
            Divider().background(PulseColor.stroke)
            statRow("7-day average",     value: "\(avgScore)")
        }
        .pulseCard()
    }

    private var proHistoryHint: some View {
        Button { showingPaywall = true } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PulseColor.blue500)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(PulseColor.blue50))
                VStack(alignment: .leading, spacing: 2) {
                    Text("See your full history")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Free shows the last \(HistoryFilter.freeWindowDays) days. Pro unlocks all of it.")
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.plain)
    }

    private var daysTracked: Int {
        guard let first = records.last?.timestamp else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
        return max(1, days)
    }
    private var bestDay: String {
        guard let r = records.max(by: { $0.pulseScore < $1.pulseScore }) else { return "—" }
        return "\(r.pulseScore) · " + r.timestamp.formatted(.dateTime.month(.abbreviated).day())
    }

    private func statRow(_ title: String, value: String, trailing: String? = nil) -> some View {
        HStack {
            Text(title).font(PulseFont.body).foregroundStyle(PulseColor.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                Text(value).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
                if let t = trailing {
                    Text(t).font(PulseFont.callout).foregroundStyle(PulseColor.fair)
                }
            }
        }
        .padding(.vertical, PulseSpace.m)
    }

    // MARK: - Derived

    private var latest: ScanRecord? { records.first }

    private var recentWeek: [ScanRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return records.filter { $0.timestamp >= cutoff }.reversed()
    }

    private var avgScore: Int {
        guard !recentWeek.isEmpty else { return latest?.pulseScore ?? 0 }
        return recentWeek.map(\.pulseScore).reduce(0, +) / recentWeek.count
    }

    private var personality: Personality {
        PersonalityClassifier.classify(records, latest: latest)
    }

    // MARK: - Share

    @MainActor
    private func shareTapped() {
        Haptics.tap()
        let img = ShareCardRenderer.render(
            score: latest?.pulseScore ?? 0,
            personality: personality,
            variant: .light
        )
        shareImage = img
        if img != nil { showingShare = true }
    }
}

private struct EmptyTrendPlaceholder: View {
    var body: some View {
        VStack(spacing: PulseSpace.s) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(PulseColor.textTertiary)
            Text("Run scans to build your trend")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}
