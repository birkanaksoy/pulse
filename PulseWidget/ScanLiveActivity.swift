import WidgetKit
import SwiftUI
import ActivityKit

private let brandBlue   = Color(red: 0.184, green: 0.420, blue: 1.000)
private let brandLight  = Color(red: 0.431, green: 0.765, blue: 1.000)

struct ScanLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScanActivityAttributes.self) { context in
            // Lock Screen / Banner
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("Pulse").font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: "waveform.path.ecg").foregroundStyle(brandBlue)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let s = context.state.finalScore {
                        Text("\(s)")
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(brandBlue)
                    } else {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        if context.state.finalScore == nil {
                            ProgressView(value: context.state.progress)
                                .tint(brandBlue)
                        }
                        Text(context.state.phase).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(brandBlue)
            } compactTrailing: {
                if let s = context.state.finalScore {
                    Text("\(s)").monospacedDigit()
                } else {
                    Text("\(Int(context.state.progress * 100))%").monospacedDigit()
                }
            } minimal: {
                if let s = context.state.finalScore {
                    Text("\(s)").font(.system(size: 12, weight: .semibold, design: .rounded))
                } else {
                    Image(systemName: "waveform.path.ecg").foregroundStyle(brandBlue)
                }
            }
        }
    }
}

private struct LockScreenView: View {
    var state: ScanActivityAttributes.ContentState
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 6)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: state.finalScore != nil ? 1 : state.progress)
                    .stroke(
                        LinearGradient(colors: [brandBlue, brandLight],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                if let s = state.finalScore {
                    Text("\(s)").font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white).monospacedDigit()
                } else {
                    Image(systemName: "waveform.path.ecg").foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Pulse").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text(state.phase).font(.caption).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding(16)
    }
}
