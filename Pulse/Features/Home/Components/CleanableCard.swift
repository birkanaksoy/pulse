import SwiftUI

struct CleanableCard: View {
    var onTap: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [PulseColor.blue500, PulseColor.blue300],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    if BytesFreedTracker.allTime > 0 {
                        Text("Freed \(BytesFreedTracker.formattedAllTime) so far")
                            .font(PulseFont.titleM)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text("Tap to clean more.")
                            .font(PulseFont.callout)
                            .foregroundStyle(PulseColor.textSecondary)
                    } else {
                        Text("Clean up your photos")
                            .font(PulseFont.titleM)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text("Duplicates, screenshots, large videos.")
                            .font(PulseFont.callout)
                            .foregroundStyle(PulseColor.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.card)
    }
}
