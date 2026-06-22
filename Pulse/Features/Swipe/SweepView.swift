import SwiftUI
import Photos

/// Top-level container that loads the photo queue, hosts the swipe stack,
/// and finally shows the delete-confirm screen.
struct SweepView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @State private var queue = PhotoQueue()
    @State private var session = SwipeSession()
    @State private var phase: Phase = .loading
    @State private var sessionFreed: Int64 = 0
    @State private var showingPaywall = false

    enum Phase { case loading, denied, swiping, confirming, done, empty, limitReached }

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            content
        }
        .task { await start() }
        .sheet(isPresented: $showingPaywall) {
            SpecialOfferPaywallView(seenOffer: .constant(true))
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:      loadingScreen
        case .denied:       deniedScreen
        case .limitReached: limitReachedScreen
        case .swiping:      SwipeStackView(session: session) { phase = .confirming }
        case .confirming:   DeleteConfirmView(session: session) { freed in
                                sessionFreed = freed
                                phase = freed > 0 ? .done : .empty
                                Analytics.track(.scanCompleted(scoreBucket: .good))
                                askForRatingIfAppropriate()
                            } onContinueSwiping: {
                                phase = .swiping
                            }
        case .done:         doneScreen
        case .empty:        emptyScreen
        }
    }

    // MARK: - Screens

    private var loadingScreen: some View {
        VStack(spacing: 18) {
            Spacer()
            PulseLogo(size: 96, shadow: true)
            ProgressView().tint(PulseColor.blue500).scaleEffect(1.1)
            Text("Loading your library…")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(PulseColor.textSecondary)
            Spacer()
        }
    }

    private var deniedScreen: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(PulseColor.fair)
            Text("Photo access denied")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pulse needs read+write access to suggest items to delete.")
                .font(.system(size: 15))
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            PrimaryButton(title: "Open Settings", systemImage: "arrow.up.right") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var limitReachedScreen: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [PulseColor.blue500, PulseColor.purple, PulseColor.teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "infinity")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.white)
            }
            .shadow(color: PulseColor.blue500.opacity(0.4), radius: 22, y: 10)

            VStack(spacing: 8) {
                Text("Daily sweep used")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                Text("Free includes one sweep a day. Go Pro for unlimited sweeps and an icon picker.")
                    .font(.system(size: 15))
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer()
            PrimaryButton(title: "Go Pro", systemImage: "arrow.right") {
                showingPaywall = true
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 24)
        }
    }

    private var doneScreen: some View {
        ZStack {
            ConfettiBurst()
                .offset(y: -40)

            VStack(spacing: 24) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [PulseColor.excellent.opacity(0.20), .clear],
                                center: .center, startRadius: 0, endRadius: 160
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 16)
                    Image(systemName: "sparkles")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .symbolEffect(.bounce, value: sessionFreed)
                }

                VStack(spacing: 6) {
                    Text("Freed")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(PulseColor.textSecondary)
                    Text(ByteCountFormatter.string(fromByteCount: sessionFreed, countStyle: .file))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .monospacedDigit()
                        .kerning(-1.5)
                        .contentTransition(.numericText(value: Double(sessionFreed)))
                }

                Text(doneSubtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Spacer()

                PrimaryButton(title: sweepAgainCTA, systemImage: "arrow.clockwise") {
                    Task { await restart() }
                }
                .padding(.horizontal, 24)
                Spacer().frame(height: 24)
            }
        }
        .onAppear { Haptics.success() }
    }

    private var doneSubtitle: LocalizedStringKey {
        let mb = Double(sessionFreed) / (1024 * 1024)
        if mb >= 5000 { return "That's roughly 1,200 photos of breathing room. Nice work." }
        if mb >= 1000 { return "About 250 photos worth. Your phone thanks you." }
        if mb >= 100  { return "Tidy. Your phone has a little more room to think." }
        if mb > 0     { return "Every byte counts." }
        return "Your phone is squeaky clean."
    }

    @State private var emptyPulse = false

    private var emptyScreen: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [PulseColor.excellent.opacity(0.22), .clear],
                            center: .center, startRadius: 0, endRadius: 140
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 16)
                    .scaleEffect(emptyPulse ? 1.06 : 1.0)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(emptyPulse ? 1.03 : 1.0)
            }
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: emptyPulse)

            VStack(spacing: 8) {
                Text("All clear ✨")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                Text("Nothing obvious to clean right now. Check back after you've taken more photos.")
                    .font(.system(size: 15))
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .onAppear { emptyPulse = true }
    }

    // MARK: - Helpers

    private var sweepAgainCTA: LocalizedStringKey {
        entitlements.isPro ? "Sweep again" : "Sweep again (Pro)"
    }

    private func askForRatingIfAppropriate() {
        guard sessionFreed > 0 else { return }
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            RatingPrompt.recordScan()
            RatingPrompt.maybeAsk(currentScore: 90, in: scene)
        }
    }

    // MARK: - Actions

    private func start() async {
        // Enforce daily limit before doing anything else.
        if !SweepLimits.canStart(isPro: entitlements.isPro) {
            phase = .limitReached
            return
        }

        if queue.state == .idle { await queue.load() }
        switch queue.state {
        case .denied:
            phase = .denied
        case .ready:
            if queue.assets.isEmpty {
                phase = .empty
            } else {
                session.load(queue.assets)
                SweepLimits.recordStart()
                phase = .swiping
            }
        default:
            phase = .loading
        }
    }

    private func restart() async {
        // 'Sweep again' is a brand-new session — also counts toward the limit.
        if !SweepLimits.canStart(isPro: entitlements.isPro) {
            showingPaywall = true
            return
        }
        queue = PhotoQueue()
        session = SwipeSession()
        sessionFreed = 0
        phase = .loading
        await start()
    }
}
