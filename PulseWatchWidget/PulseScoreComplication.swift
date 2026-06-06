import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Brand

private let blue500 = Color(red: 0.184, green: 0.420, blue: 1.000)
private let blue300 = Color(red: 0.431, green: 0.765, blue: 1.000)
private let excellent = Color(red: 0.129, green: 0.753, blue: 0.478)
private let fair = Color(red: 0.961, green: 0.647, blue: 0.141)
private let critical = Color(red: 0.937, green: 0.267, blue: 0.267)

private func statusColor(_ score: Int) -> Color {
    switch score {
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

// MARK: - Timeline

struct PulseScoreEntry: TimelineEntry {
    let date: Date
    let score: Int
    let status: String
    let scannedAt: Date
}

struct PulseScoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseScoreEntry {
        PulseScoreEntry(date: Date(), score: 86, status: "Excellent", scannedAt: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PulseScoreEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseScoreEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    /// Reads the latest ScanRecord from the iCloud-synced SwiftData container.
    private func currentEntry() -> PulseScoreEntry {
        let config = ModelConfiguration(
            "PulseStore",
            schema: Schema([ScanRecord.self]),
            cloudKitDatabase: .private("iCloud.com.birkan.pulse")
        )
        guard let container = try? ModelContainer(for: ScanRecord.self, configurations: config) else {
            return PulseScoreEntry(date: Date(), score: 0, status: String(localized: "No data"), scannedAt: Date())
        }
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let records = (try? context.fetch(descriptor)) ?? []
        guard let r = records.first else {
            return PulseScoreEntry(date: Date(), score: 0, status: String(localized: "No scan yet"), scannedAt: Date())
        }
        return PulseScoreEntry(date: Date(), score: r.pulseScore, status: statusLabel(r.pulseScore), scannedAt: r.timestamp)
    }
}

// MARK: - Widget

struct PulseScoreComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PulseScoreComplication", provider: PulseScoreProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "pulse://watch"))
        }
        .configurationDisplayName("Pulse Score")
        .description("Your phone's health at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

// MARK: - View

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PulseScoreEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    circular
        case .accessoryRectangular: rectangular
        case .accessoryInline:      inline
        case .accessoryCorner:      corner
        default:                    circular
        }
    }

    private var circular: some View {
        Gauge(value: Double(entry.score), in: 0...100) {
            Image(systemName: "waveform.path.ecg")
        } currentValueLabel: {
            Text("\(entry.score)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(statusColor(entry.score))
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg").font(.caption2)
                Text("Pulse").font(.caption2.weight(.semibold))
            }
            Text("\(entry.score)")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(statusColor(entry.score))
            Text(entry.status)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var inline: some View {
        Label("Pulse \(entry.score)", systemImage: "waveform.path.ecg")
    }

    private var corner: some View {
        Text("\(entry.score)")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .widgetLabel("Pulse")
    }
}
