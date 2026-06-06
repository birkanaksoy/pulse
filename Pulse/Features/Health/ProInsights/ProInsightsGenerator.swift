import Foundation

struct ProInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let valueText: String?   // optional bold metric
}

/// Generates rich, statistics-backed insights from scan history.
/// All math is honest — falls back to "need more data" rather than inventing.
enum ProInsightsGenerator {
    /// Minimum records before a given insight should appear.
    private static let minSamples = 7

    static func generate(_ records: [ScanRecord]) -> [ProInsight] {
        guard records.count >= minSamples else { return [] }
        var out: [ProInsight] = []

        if let i = storageProjection(records) { out.append(i) }
        if let i = weekdayThermal(records) { out.append(i) }
        if let i = scoreStability(records) { out.append(i) }
        if let i = bestTimeOfDay(records) { out.append(i) }
        if let i = lowPowerCorrelation(records) { out.append(i) }
        if let i = averageScore(records) { out.append(i) }

        return out
    }

    // MARK: - Storage projection (linear regression on storageUsed%)

    private static func storageProjection(_ records: [ScanRecord]) -> ProInsight? {
        // Sort oldest → newest for regression.
        let sorted = records.sorted { $0.timestamp < $1.timestamp }
        let first = sorted.first!
        let xs = sorted.map { $0.timestamp.timeIntervalSince(first.timestamp) / 86_400 } // days
        let ys = sorted.map { Double($0.storageUsed) }

        // Need a sane time window (≥ 5 days span).
        guard let lastX = xs.last, lastX >= 5 else { return nil }

        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = (n * sumXX - sumX * sumX)
        guard denom != 0 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom  // % per day

        guard slope > 0.05 else {
            return ProInsight(
                icon: "checkmark.circle",
                title: String(localized: "Storage stable"),
                body: String(localized: "Your storage usage isn't trending up over the last \(Int(lastX)) days."),
                valueText: nil
            )
        }

        let currentUsed = Double(records.first?.storageUsed ?? 0)
        let remaining = max(0, 100 - currentUsed)
        let daysUntilFull = remaining / slope
        if !daysUntilFull.isFinite || daysUntilFull > 365 * 2 {
            return ProInsight(
                icon: "internaldrive",
                title: String(localized: "Storage growing slowly"),
                body: String(localized: "At current pace, you have plenty of runway."),
                valueText: nil
            )
        }
        let weeks = Int((daysUntilFull / 7).rounded())
        return ProInsight(
            icon: "exclamationmark.triangle",
            title: String(localized: "Storage projection"),
            body: String(localized: "At your current growth rate, you'll hit 100% in about \(weeks) weeks."),
            valueText: "+\(String(format: "%.2f", slope))%/day"
        )
    }

    // MARK: - Weekday thermal pattern

    private static func weekdayThermal(_ records: [ScanRecord]) -> ProInsight? {
        let cal = Calendar.current
        var byWeekday: [Int: [Int]] = [:]
        for r in records {
            let wd = cal.component(.weekday, from: r.timestamp)
            byWeekday[wd, default: []].append(r.thermalRaw)
        }
        guard byWeekday.count >= 3 else { return nil }

        let avgs = byWeekday.mapValues { Double($0.reduce(0, +)) / Double($0.count) }
        guard let hottest = avgs.max(by: { $0.value < $1.value }),
              let coolest = avgs.min(by: { $0.value < $1.value }),
              hottest.value - coolest.value >= 0.5 else { return nil }

        let f = DateFormatter()
        f.locale = .current
        let weekdays = f.standaloneWeekdaySymbols ?? []
        let hottestName = weekdays[hottest.key - 1]
        return ProInsight(
            icon: "thermometer.sun",
            title: String(localized: "Warmest weekday"),
            body: String(localized: "Your phone runs warmer on \(hottestName) than other days."),
            valueText: hottestName
        )
    }

    // MARK: - Score stability (std dev of pulseScore)

    private static func scoreStability(_ records: [ScanRecord]) -> ProInsight? {
        let scores = records.map { Double($0.pulseScore) }
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
        let std = sqrt(variance)

        let label: String
        let body: String
        switch std {
        case ..<5:
            label = String(localized: "Very stable")
            body  = String(localized: "Your score barely moves between scans.")
        case ..<10:
            label = String(localized: "Stable")
            body  = String(localized: "Your score holds steady most days.")
        case ..<20:
            label = String(localized: "Variable")
            body  = String(localized: "Your score swings a fair bit between scans.")
        default:
            label = String(localized: "Unstable")
            body  = String(localized: "Your score swings widely — something is changing day-to-day.")
        }
        return ProInsight(
            icon: "waveform",
            title: String(localized: "Score stability"),
            body: body,
            valueText: label
        )
    }

    // MARK: - Best time of day (highest avg score)

    private static func bestTimeOfDay(_ records: [ScanRecord]) -> ProInsight? {
        let cal = Calendar.current
        var byBucket: [Int: [Int]] = [:]  // 0=night, 1=morning, 2=afternoon, 3=evening
        for r in records {
            let h = cal.component(.hour, from: r.timestamp)
            let b: Int = {
                switch h { case 5..<12: return 1; case 12..<17: return 2; case 17..<22: return 3; default: return 0 }
            }()
            byBucket[b, default: []].append(r.pulseScore)
        }
        guard byBucket.count >= 2 else { return nil }
        let avgs = byBucket.mapValues { Double($0.reduce(0, +)) / Double($0.count) }
        guard let best = avgs.max(by: { $0.value < $1.value }) else { return nil }
        let label: String = {
            switch best.key {
            case 1: return String(localized: "Morning")
            case 2: return String(localized: "Afternoon")
            case 3: return String(localized: "Evening")
            default: return String(localized: "Night")
            }
        }()
        return ProInsight(
            icon: "sun.max",
            title: String(localized: "Best time to scan"),
            body: String(localized: "Your phone scores highest in the \(label.lowercased())."),
            valueText: label
        )
    }

    // MARK: - Low Power Mode frequency

    private static func lowPowerCorrelation(_ records: [ScanRecord]) -> ProInsight? {
        let total = records.count
        let lpmOn = records.filter { $0.lowPowerMode == true }.count
        guard total > 0, lpmOn > 0 else { return nil }
        let pct = Int(Double(lpmOn) / Double(total) * 100)
        return ProInsight(
            icon: "leaf",
            title: String(localized: "Low Power Mode use"),
            body: String(localized: "\(pct)% of your scans were taken with Low Power Mode on."),
            valueText: "\(pct)%"
        )
    }

    // MARK: - All-time average

    private static func averageScore(_ records: [ScanRecord]) -> ProInsight? {
        let avg = records.map(\.pulseScore).reduce(0, +) / records.count
        let best = records.map(\.pulseScore).max() ?? 0
        let worst = records.map(\.pulseScore).min() ?? 0
        return ProInsight(
            icon: "chart.bar",
            title: String(localized: "All-time average"),
            body: String(localized: "Across \(records.count) scans, you average \(avg). Best: \(best). Worst: \(worst)."),
            valueText: "\(avg)"
        )
    }
}
