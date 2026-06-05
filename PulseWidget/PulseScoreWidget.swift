import WidgetKit
import SwiftUI

struct PulseEntry: TimelineEntry {
    let date: Date
    let score: Int
    let status: String
    let isPro: Bool
}

struct PulseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseEntry {
        PulseEntry(date: Date(), score: 86, status: "Excellent", isPro: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (PulseEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh hourly; Home explicitly reloads on scan.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> PulseEntry {
        if let snap = SharedScoreStore.load() {
            return PulseEntry(date: snap.timestamp, score: snap.score, status: snap.status, isPro: snap.isPro)
        }
        return PulseEntry(date: Date(), score: 0, status: "No scan yet", isPro: false)
    }
}

struct PulseScoreWidget: Widget {
    let kind: String = "PulseScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseProvider()) { entry in
            PulseWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Pulse Score")
        .description("Your phone's health at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct PulseWidgetView: View {
    var entry: PulseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.isPro {
            switch family {
            case .accessoryCircular:    circular
            case .accessoryRectangular: rectangular
            case .accessoryInline:      inline
            case .systemMedium:         medium
            default:                    small
            }
        } else {
            switch family {
            case .accessoryCircular:    lockedCircular
            case .accessoryRectangular: lockedRectangular
            case .accessoryInline:      Text("Pulse · Pro")
            default:                    upsell
            }
        }
    }

    // MARK: - Lock Screen variants

    private var circular: some View {
        Gauge(value: Double(entry.score), in: 0...100) {
            Image(systemName: "waveform.path.ecg")
        } currentValueLabel: {
            Text("\(entry.score)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption2)
                Text("Pulse")
                    .font(.caption2.weight(.semibold))
            }
            Text("\(entry.score)")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            Text(entry.status)
                .font(.caption2)
        }
    }

    private var inline: some View {
        Label("Pulse \(entry.score) · \(entry.status)", systemImage: "waveform.path.ecg")
    }

    // MARK: - Locked variants (Pro upsell)

    private var lockedCircular: some View {
        Gauge(value: 0) {
            Image(systemName: "lock.fill")
        } currentValueLabel: {
            Image(systemName: "lock.fill").font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var lockedRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill").font(.caption2)
                Text("Pulse Pro").font(.caption2.weight(.semibold))
            }
            Text("Unlock widget")
                .font(.system(size: 16, weight: .semibold))
            Text("Tap to upgrade").font(.caption2)
        }
    }

    private var upsell: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.184, green: 0.420, blue: 1.000))
            Spacer()
            Text("Pulse widget")
                .font(.subheadline.weight(.semibold))
            Text("Unlock with Pro")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            ringMini(size: 64)
            Spacer()
            Text("\(entry.score)")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text(entry.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ringMini(size: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text("Pulse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(entry.score)")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                Text(entry.status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func ringMini(size: CGFloat) -> some View {
        let progress = Double(entry.score) / 100.0
        return ZStack {
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.184, green: 0.420, blue: 1.000),
                                 Color(red: 0.431, green: 0.765, blue: 1.000)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
