import SwiftUI

struct OnboardingView: View {
    @Binding var didOnboard: Bool
    @State private var page: Int = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                valuePropsPage.tag(1)
                firstScanPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            indicator
            cta
        }
        .padding(.bottom, PulseSpace.xxl)
        .background(PulseColor.canvas.ignoresSafeArea())
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: PulseSpace.xl) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(PulseColor.ringGradient)
                .padding(PulseSpace.xxxl)
                .background(Circle().fill(PulseColor.blue50))
            VStack(spacing: PulseSpace.s) {
                Text("Know your phone's\nhealth in seconds.")
                    .font(PulseFont.titleXL)
                    .foregroundStyle(PulseColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Pulse is your phone's diagnostic system.")
                    .font(PulseFont.body)
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PulseSpace.xxl)
            Spacer()
        }
    }

    private var valuePropsPage: some View {
        VStack(spacing: PulseSpace.xxl) {
            Spacer()
            Text("Honest signals. No guesswork.")
                .font(PulseFont.titleL)
                .foregroundStyle(PulseColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulseSpace.xxl)
            VStack(spacing: PulseSpace.l) {
                valueProp("waveform.path.ecg", "Diagnose", "One score from real iOS signals.")
                valueProp("sparkles",          "Suggest",  "We recommend. You decide.")
                valueProp("chart.xyaxis.line", "Track",    "Watch your phone over time.")
            }
            .padding(.horizontal, PulseSpace.xxl)
            Spacer()
        }
    }

    private func valueProp(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: PulseSpace.l) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(PulseColor.blue500)
                .frame(width: 48, height: 48)
                .background(Circle().fill(PulseColor.blue50))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PulseFont.titleM).foregroundStyle(PulseColor.textPrimary)
                Text(subtitle).font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
        }
    }

    private var firstScanPage: some View {
        VStack(spacing: PulseSpace.xl) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(PulseColor.stroke, lineWidth: 14)
                    .frame(width: 240, height: 240)
                Image(systemName: "play.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(PulseColor.blue500)
                    .offset(x: 4)
            }
            VStack(spacing: PulseSpace.s) {
                Text("Ready when you are")
                    .font(PulseFont.titleL)
                    .foregroundStyle(PulseColor.textPrimary)
                Text("Your first real scan starts on the next screen. Everything is computed on-device.")
                    .font(PulseFont.body)
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PulseSpace.xxl)
            Spacer()
        }
    }

    // MARK: - CTA

    private var indicator: some View {
        HStack(spacing: PulseSpace.s) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == page ? PulseColor.blue500 : PulseColor.stroke)
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .padding(.bottom, PulseSpace.l)
    }

    private var cta: some View {
        PrimaryButton(
            title: page < 2 ? "Continue" : "Run my first scan",
            systemImage: "arrow.right"
        ) {
            if page < 2 {
                withAnimation { page += 1 }
            } else {
                didOnboard = true
            }
        }
        .padding(.horizontal, PulseSpace.xl)
    }
}
