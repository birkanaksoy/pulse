import SwiftUI

struct RecommendationCard: View {
    var recommendation: Recommendation
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: recommendation.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text(recommendation.body)
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
            }

            Button {
                Haptics.tap(0.5)
                recommendation.action.perform()
                if recommendation.action == .dismiss { onDismiss() }
            } label: {
                HStack(spacing: PulseSpace.s) {
                    Image(systemName: recommendation.action.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                    Text(recommendation.action.label)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(PulseColor.blue500)
                .padding(.horizontal, PulseSpace.l)
                .padding(.vertical, PulseSpace.s)
                .background(Capsule().fill(PulseColor.blue50))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCard()
    }
}
