import SwiftUI

/// 7×24 grid of average thermal state by weekday × hour. Honest: cells with no
/// data shown as a thin track; cells with samples shaded from green to red.
struct ThermalHeatmap: View {
    var records: [ScanRecord]

    private let weekdayLabels: [String] = {
        let f = DateFormatter()
        f.locale = .current
        return (f.shortStandaloneWeekdaySymbols ?? []).map { String($0.prefix(1)) }
    }()

    var body: some View {
        let grid = computeGrid()
        VStack(alignment: .leading, spacing: PulseSpace.s) {
            HStack(spacing: 2) {
                Color.clear.frame(width: 16)
                ForEach(0..<24, id: \.self) { h in
                    Text(h % 6 == 0 ? "\(h)" : "")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(PulseColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<7, id: \.self) { wd in
                HStack(spacing: 2) {
                    Text(weekdayLabels[wd])
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(PulseColor.textTertiary)
                        .frame(width: 16, alignment: .leading)
                    ForEach(0..<24, id: \.self) { h in
                        cell(value: grid[wd][h])
                    }
                }
            }
            legend
        }
    }

    @ViewBuilder
    private func cell(value: Double?) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color(for: value))
            .frame(maxWidth: .infinity)
            .frame(height: 14)
    }

    private func color(for value: Double?) -> Color {
        guard let v = value else { return PulseColor.stroke.opacity(0.6) }
        // 0..1 → green → blue → amber → red
        switch v {
        case ..<0.5:  return PulseColor.excellent.opacity(0.4 + v)
        case ..<1.5:  return PulseColor.blue500.opacity(0.5)
        case ..<2.5:  return PulseColor.fair.opacity(0.7)
        default:      return PulseColor.critical.opacity(0.85)
        }
    }

    private var legend: some View {
        HStack(spacing: PulseSpace.m) {
            legendDot(color: PulseColor.excellent, label: "Nominal")
            legendDot(color: PulseColor.blue500, label: "Fair")
            legendDot(color: PulseColor.fair, label: "Warm")
            legendDot(color: PulseColor.critical, label: "Hot")
            Spacer()
            legendDot(color: PulseColor.stroke.opacity(0.6), label: "No data")
        }
        .padding(.top, PulseSpace.s)
    }

    private func legendDot(color: Color, label: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color).frame(width: 10, height: 10)
            Text(label).font(.system(size: 10)).foregroundStyle(PulseColor.textTertiary)
        }
    }

    /// 7 × 24 average thermalRaw, or nil if no samples in cell.
    private func computeGrid() -> [[Double?]] {
        let cal = Calendar.current
        var sums = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
        var counts = Array(repeating: Array(repeating: 0, count: 24), count: 7)
        for r in records {
            let wd = cal.component(.weekday, from: r.timestamp) - 1 // 0..6
            let h  = cal.component(.hour, from: r.timestamp)
            guard (0..<7).contains(wd), (0..<24).contains(h) else { continue }
            sums[wd][h] += Double(r.thermalRaw)
            counts[wd][h] += 1
        }
        var result: [[Double?]] = []
        for wd in 0..<7 {
            var row: [Double?] = []
            for h in 0..<24 {
                let c = counts[wd][h]
                row.append(c == 0 ? nil : sums[wd][h] / Double(c))
            }
            result.append(row)
        }
        return result
    }
}
