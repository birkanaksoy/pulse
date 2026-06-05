import SwiftUI

struct ShareCardView: View {
    var score: Int
    var personality: Personality
    var variant: Variant = .light

    enum Variant { case light, dark }

    private var bg: Color {
        variant == .light ? .white : PulseColor.textPrimary
    }
    private var fg: Color {
        variant == .light ? PulseColor.textPrimary : .white
    }
    private var subFg: Color {
        variant == .light ? PulseColor.textSecondary : Color.white.opacity(0.7)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Text("My Pulse Score")
                    .font(PulseFont.titleM)
                    .foregroundStyle(subFg)
                PulseRing(score: score, size: 320)
                VStack(spacing: 8) {
                    Text("\(personality.emoji) \(personality.name)")
                        .font(PulseFont.titleL)
                        .foregroundStyle(fg)
                    Text(personality.subtitle)
                        .font(PulseFont.body)
                        .foregroundStyle(subFg)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                Spacer()
                Text("pulse.app")
                    .font(PulseFont.callout)
                    .foregroundStyle(subFg)
                    .padding(.bottom, 60)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}
