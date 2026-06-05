import SwiftUI

struct ComingSoonScreen: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(spacing: PulseSpace.l) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(PulseColor.blue500)
                .padding(PulseSpace.xxl)
                .background(
                    Circle().fill(PulseColor.blue50)
                )
            Text(title)
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text(subtitle)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
            Text("Coming soon")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
                .padding(.horizontal, PulseSpace.l)
                .padding(.vertical, PulseSpace.s)
                .background(
                    Capsule().fill(PulseColor.muted)
                )
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(PulseColor.canvas.ignoresSafeArea())
    }
}
