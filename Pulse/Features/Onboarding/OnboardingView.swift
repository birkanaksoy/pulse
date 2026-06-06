import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var didOnboard: Bool
    @State private var page: Int = 0
    @State private var weeklyReminderRequested = false
    @AppStorage("pulse.weeklyReminder") private var weeklyReminder = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = 4

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    valuePropsPage.tag(1)
                    notificationPage.tag(2)
                    firstScanPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: page)

                Spacer(minLength: 0)
                indicator
                cta
                if page == 2 { skipReminder }
            }
            .padding(.bottom, PulseSpace.xxl)
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        ParallaxPage(page: page, index: 0) {
            VStack(spacing: PulseSpace.xl) {
                Spacer()
                glyph(systemName: "waveform.path.ecg")
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
    }

    private var valuePropsPage: some View {
        ParallaxPage(page: page, index: 1) {
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
    }

    private var notificationPage: some View {
        ParallaxPage(page: page, index: 2) {
            VStack(spacing: PulseSpace.xxl) {
                Spacer()
                glyph(systemName: "bell.badge")
                VStack(spacing: PulseSpace.s) {
                    Text("One nudge a week.")
                        .font(PulseFont.titleL)
                        .foregroundStyle(PulseColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("A Sunday reminder to scan. Local only — nothing leaves your phone.")
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PulseSpace.xxl)
                }
                Spacer()
            }
        }
    }

    private var firstScanPage: some View {
        ParallaxPage(page: page, index: 3) {
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
                        .shadow(color: PulseColor.blue500.opacity(0.35), radius: 12, y: 4)
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
    }

    // MARK: - Glyph

    private func glyph(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(
                LinearGradient(
                    colors: [PulseColor.blue500, PulseColor.blue300],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .padding(PulseSpace.xxxl)
            .background(Circle().fill(PulseColor.blue50))
            .shadow(color: PulseColor.blue500.opacity(0.25), radius: 30, y: 12)
    }

    private func valueProp(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: PulseSpace.l) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [PulseColor.blue500, PulseColor.blue300],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: PulseColor.blue500.opacity(0.3), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PulseFont.titleM).foregroundStyle(PulseColor.textPrimary)
                Text(subtitle).font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - CTA

    private var indicator: some View {
        HStack(spacing: PulseSpace.s) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? PulseColor.blue500 : PulseColor.stroke)
                    .frame(width: i == page ? 28 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .padding(.bottom, PulseSpace.l)
    }

    private var cta: some View {
        PrimaryButton(
            title: ctaTitle,
            systemImage: "arrow.right"
        ) {
            handleCTA()
        }
        .padding(.horizontal, PulseSpace.xl)
    }

    private var ctaTitle: LocalizedStringKey {
        switch page {
        case 2:  return weeklyReminderRequested ? "Continue" : "Enable weekly check-in"
        case 3:  return "Run my first scan"
        default: return "Continue"
        }
    }

    private var skipReminder: some View {
        Button {
            advance()
        } label: {
            Text("Maybe later")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textTertiary)
                .padding(.top, PulseSpace.s)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handleCTA() {
        switch page {
        case 2 where !weeklyReminderRequested:
            Task { await requestNotificationPermission() }
        default:
            advance()
        }
    }

    private func advance() {
        if page < totalPages - 1 {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.5)) { page += 1 }
        } else {
            didOnboard = true
        }
    }

    @MainActor
    private func requestNotificationPermission() async {
        let granted = await NotificationScheduler.requestAuthorization()
        weeklyReminderRequested = true
        if granted {
            NotificationScheduler.scheduleWeeklyReminder()
            weeklyReminder = true
        }
        // Always advance — granted or not, we move on. User can revisit in Settings.
        advance()
    }
}

/// Wraps an onboarding page with subtle parallax + scale based on swipe position.
private struct ParallaxPage<Content: View>: View {
    var page: Int
    var index: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            let mid = frame.midX
            let screen = UIScreen.main.bounds.width
            let offset = (mid - screen / 2) / screen
            let opacity = 1 - min(1, abs(offset) * 1.4)
            let scale = 0.96 + (1 - min(1, abs(offset))) * 0.04

            content()
                .opacity(opacity)
                .scaleEffect(scale)
                .offset(y: abs(offset) * 8)
        }
    }
}
