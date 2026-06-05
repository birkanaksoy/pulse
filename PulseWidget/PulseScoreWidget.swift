import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Brand colors (self-contained so the widget needs no main-app types)

private enum BrandColor {
    static let blue500 = Color(red: 0.184, green: 0.420, blue: 1.000)
    static let blue300 = Color(red: 0.431, green: 0.765, blue: 1.000)
    static let excellent = Color(red: 0.129, green: 0.753, blue: 0.478)
    static let fair      = Color(red: 0.961, green: 0.647, blue: 0.141)
    static let critical  = Color(red: 0.937, green: 0.267, blue: 0.267)

    static func statusColor(for score: Int) -> Color {
        switch score {
        case 85...: return excellent
        case 65...: return blue500
        case 40...: return fair
        default:    return critical
        }
    }

    static func statusLabel(for score: Int) -> String {
        switch score {
        case 85...: return String(localized: "Excellent")
        case 65...: return String(localized: "Good")
        case 40...: return String(localized: "Fair")
        default:    return String(localized: "Critical")
        }
    }
}

// MARK: - Timeline

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
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func currentEntry() -> PulseEntry {
        if let snap = SharedScoreStore.load() {
            return PulseEntry(date: snap.timestamp, score: snap.score, status: snap.status, isPro: snap.isPro)
        }
        return PulseEntry(date: Date(), score: 0, status: String(localized: "No scan yet"), isPro: false)
    }
}

// MARK: - Widget

struct PulseScoreWidget: Widget {
    let kind: String = "PulseScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseProvider()) { entry in
            PulseWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground(score: entry.score, isPro: entry.isPro)
                }
        }
        .configurationDisplayName("Pulse Score")
        .description("Your phone's health at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Background (Home Screen widgets only — accessory widgets ignore it)

private struct WidgetBackground: View {
    var score: Int
    var isPro: Bool
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            if isPro {
                LinearGradient(
                    colors: [BrandColor.statusColor(for: score).opacity(0.12),
                             BrandColor.blue300.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Root view (routes by family / Pro state)

struct PulseWidgetView: View {
    var entry: PulseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.isPro {
            switch family {
            case .accessoryCircular:    AccessoryCircular(score: entry.score)
            case .accessoryRectangular: AccessoryRectangular(entry: entry)
            case .accessoryInline:      AccessoryInline(entry: entry)
            case .systemMedium:         MediumWidget(entry: entry)
            default:                    SmallWidget(entry: entry)
            }
        } else {
            switch family {
            case .accessoryCircular:    LockedCircular()
            case .accessoryRectangular: LockedRectangular()
            case .accessoryInline:      Text("Pulse · Pro")
            default:                    LockedHomeScreen()
            }
        }
    }
}

// MARK: - Home Screen variants (Pro)

private struct SmallWidget: View {
    var entry: PulseEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ScoreRing(score: entry.score, lineWidth: 8, size: 64)
                Spacer()
                Button(intent: ScanIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BrandColor.blue500)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(.thinMaterial))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text("\(entry.score)")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(entry.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct MediumWidget: View {
    var entry: PulseEntry
    var body: some View {
        HStack(spacing: 16) {
            ScoreRing(score: entry.score, lineWidth: 10, size: 96)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pulse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(entry.score)")
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(entry.status)
                    .font(.subheadline)
                    .foregroundStyle(BrandColor.statusColor(for: entry.score))
                Text(entry.date, format: .relative(presentation: .named, unitsStyle: .narrow))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            Button(intent: ScanIntent()) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Scan").font(.caption2)
                }
                .foregroundStyle(BrandColor.blue500)
                .frame(width: 48, height: 48)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Lock Screen variants (Pro)

private struct AccessoryCircular: View {
    var score: Int
    var body: some View {
        Gauge(value: Double(score), in: 0...100) {
            Image(systemName: "waveform.path.ecg")
        } currentValueLabel: {
            Text("\(score)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct AccessoryRectangular: View {
    var entry: PulseEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg").font(.caption2)
                Text("Pulse").font(.caption2.weight(.semibold))
            }
            Text("\(entry.score)")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(entry.status).font(.caption2)
        }
    }
}

private struct AccessoryInline: View {
    var entry: PulseEntry
    var body: some View {
        Label("Pulse \(entry.score) · \(entry.status)", systemImage: "waveform.path.ecg")
    }
}

// MARK: - Locked variants

private struct LockedHomeScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BrandColor.blue500)
            Spacer()
            Text("Pulse widget")
                .font(.subheadline.weight(.semibold))
            Text("Unlock with Pro")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct LockedCircular: View {
    var body: some View {
        Gauge(value: 0) {
            Image(systemName: "lock.fill")
        } currentValueLabel: {
            Image(systemName: "lock.fill").font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct LockedRectangular: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill").font(.caption2)
                Text("Pulse Pro").font(.caption2.weight(.semibold))
            }
            Text("Unlock widget").font(.system(size: 16, weight: .semibold))
            Text("Tap to upgrade").font(.caption2)
        }
    }
}

// MARK: - Shared ring (status-tinted gradient — matches main app feel)

private struct ScoreRing: View {
    var score: Int
    var lineWidth: CGFloat
    var size: CGFloat

    var body: some View {
        let progress = Double(score) / 100.0
        let color = BrandColor.statusColor(for: score)
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: progress > 0
                            ? [BrandColor.blue500, BrandColor.blue300, color]
                            : [color, color],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 4)
            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(width: size, height: size)
    }
}
