import SwiftUI
import SwiftData

struct WeeklyReportCard: View {
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            HStack {
                Text("Weekly Report")
                    .font(PulseFont.titleM)
                    .foregroundStyle(PulseColor.textPrimary)
                Spacer()
                Text(Date(), format: .dateTime.week())
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textTertiary)
            }
            ProLock(
                title: "Weekly insight",
                subtitle: "A digest of how your phone fared this week."
            ) {
                VStack(alignment: .leading, spacing: PulseSpace.m) {
                    reportRow("Avg score", "\(avg)", trend: trend)
                    Divider().background(PulseColor.stroke)
                    reportRow("Best day", best)
                    Divider().background(PulseColor.stroke)
                    reportRow("Watch out", watchOut)
                }
                .padding(PulseSpace.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PulseColor.muted, in: RoundedRectangle(cornerRadius: PulseRadius.card - 4))
            }
        }
        .pulseCard()
    }

    private var week: [ScanRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return records.filter { $0.timestamp >= cutoff }
    }
    private var avg: Int {
        guard !week.isEmpty else { return 0 }
        return week.map(\.pulseScore).reduce(0, +) / week.count
    }
    private var trend: String {
        // Require enough samples + a meaningful delta before claiming a direction.
        guard week.count >= 3 else { return "—" }
        let first = week.last?.pulseScore ?? 0
        let last = week.first?.pulseScore ?? 0
        let delta = last - first
        guard abs(delta) >= 5 else { return "→" }
        return delta > 0 ? "↑" : "↓"
    }
    private var best: String {
        guard let r = week.max(by: { $0.pulseScore < $1.pulseScore }) else { return "—" }
        return r.timestamp.formatted(.dateTime.weekday(.wide).locale(.current)) + " · \(r.pulseScore)"
    }
    private var watchOut: String {
        let avgStorage = week.isEmpty ? 0 : week.map(\.storageUsed).reduce(0, +) / week.count
        if avgStorage > 80 { return String(localized: "Storage running tight") }
        if week.contains(where: { $0.thermalRaw >= 2 }) { return String(localized: "Thermal events this week") }
        return String(localized: "Nothing notable. Keep it up.")
    }

    private func reportRow(_ title: String, _ value: String, trend: String? = nil) -> some View {
        HStack {
            Text(title).font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
            Spacer()
            HStack(spacing: 6) {
                Text(value).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
                if let t = trend {
                    Text(t).font(PulseFont.callout).foregroundStyle(PulseColor.blue500)
                }
            }
        }
    }
}
