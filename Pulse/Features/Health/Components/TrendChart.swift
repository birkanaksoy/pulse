import SwiftUI
import Charts

struct TrendChart: View {
    var records: [ScanRecord]

    var body: some View {
        Chart {
            ForEach(records) { r in
                AreaMark(
                    x: .value("Day", r.timestamp),
                    y: .value("Score", r.pulseScore)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [PulseColor.blue500.opacity(0.35), PulseColor.blue500.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Day", r.timestamp),
                    y: .value("Score", r.pulseScore)
                )
                .foregroundStyle(PulseColor.blue500)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { v in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    .foregroundStyle(PulseColor.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 50, 100]) { _ in
                AxisGridLine().foregroundStyle(PulseColor.stroke)
                AxisValueLabel().foregroundStyle(PulseColor.textTertiary)
            }
        }
        .frame(height: 180)
    }
}
