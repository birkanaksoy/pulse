import SwiftUI

struct ProInsightsSection: View {
    var records: [ScanRecord]
    var onShowPaywall: () -> Void

    @Environment(EntitlementStore.self) private var entitlements

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            SectionHeader("Pro Insights")

            ProLock(
                title: String(localized: "Deep insights"),
                subtitle: String(localized: "Patterns, projections, and a heatmap from your real scans.")
            ) {
                VStack(spacing: PulseSpace.l) {
                    heatmapCard
                    insightsList
                }
            }
        }
    }

    private var insights: [ProInsight] {
        ProInsightsGenerator.generate(records)
    }

    @ViewBuilder
    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Thermal heatmap · 7 days × 24 hours")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            ThermalHeatmap(records: records)
        }
        .pulseCard()
    }

    @ViewBuilder
    private var insightsList: some View {
        if insights.isEmpty {
            Text(String(localized: "Run at least 7 scans to unlock pattern insights."))
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PulseSpace.l)
                .pulseCard()
        } else {
            VStack(spacing: PulseSpace.m) {
                ForEach(insights) { i in
                    insightCard(i)
                }
            }
        }
    }

    private func insightCard(_ insight: ProInsight) -> some View {
        HStack(spacing: PulseSpace.m) {
            Image(systemName: insight.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(PulseFont.titleM)
                    .foregroundStyle(PulseColor.textPrimary)
                Text(insight.body)
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
            if let v = insight.valueText {
                Text(v)
                    .font(PulseFont.callout.weight(.semibold))
                    .foregroundStyle(PulseColor.blue500)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(PulseColor.blue50))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCard()
    }
}
