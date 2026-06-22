import SwiftUI
import Photos
import UserNotifications

struct OnboardingView: View {
    @Binding var didOnboard: Bool
    @State private var page: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = 3

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    valuePage.tag(1)
                    permissionPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .smooth(duration: 0.55), value: page)

                indicator
                cta
                Spacer().frame(height: 24)
            }
            .padding(.bottom, 8)
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            PulseLogo(size: 132)
                .shadow(color: PulseColor.blue500.opacity(0.25), radius: 30, y: 12)
            VStack(spacing: 10) {
                Text("Clean your phone\nwith a swipe.")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Real deletion. iOS confirms. Nothing leaves your device.")
                    .font(.system(size: 16))
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var valuePage: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                row(icon: "hand.draw", title: "Swipe to decide",
                    body: "Left = delete · Right = keep")
                row(icon: "trash", title: "Confirm in one tap",
                    body: "iOS shows the system delete dialog.")
                row(icon: "checkmark.seal", title: "Brag a little",
                    body: "Watch your freed-bytes counter grow.")
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func row(icon: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: PulseColor.blue500.opacity(0.3), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PulseColor.textPrimary)
                Text(body).font(.system(size: 14))
                    .foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
        }
    }

    private var permissionPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(PulseColor.ringGradient)
                .padding(28)
                .background(Circle().fill(PulseColor.blue50))
            VStack(spacing: 10) {
                Text("One permission to get started")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Pulse needs read+write access to your photos. We never upload — every delete is confirmed by iOS itself.")
                    .font(.system(size: 15))
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? PulseColor.blue500 : PulseColor.stroke)
                    .frame(width: i == page ? 28 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .padding(.bottom, 16)
    }

    private var cta: some View {
        PrimaryButton(
            title: page < totalPages - 1 ? "Continue" : "Allow & start",
            systemImage: "arrow.right"
        ) {
            handleCTA()
        }
        .padding(.horizontal, 24)
    }

    private func handleCTA() {
        if page < totalPages - 1 {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.45)) { page += 1 }
        } else {
            Task {
                _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                didOnboard = true
            }
        }
    }
}
