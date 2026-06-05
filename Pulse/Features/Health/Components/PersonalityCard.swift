import SwiftUI

struct PersonalityCard: View {
    var personality: Personality
    var onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Phone Personality")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textTertiary)
            HStack(alignment: .top, spacing: PulseSpace.m) {
                Text(personality.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(personality.name)
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text(personality.subtitle)
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
            }
            Button(action: onShare) {
                HStack(spacing: PulseSpace.s) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.system(size: 15, weight: .semibold))
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
