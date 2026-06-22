import SwiftUI
import Photos

/// Top-level container that loads the photo queue, hosts the swipe stack,
/// and finally shows the delete-confirm screen.
struct SweepView: View {
    @State private var queue = PhotoQueue()
    @State private var session = SwipeSession()
    @State private var phase: Phase = .loading
    @State private var sessionFreed: Int64 = 0

    enum Phase { case loading, denied, swiping, confirming, done, empty }

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            content
        }
        .task { await start() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:    loadingScreen
        case .denied:     deniedScreen
        case .swiping:    SwipeStackView(session: session) { phase = .confirming }
        case .confirming: DeleteConfirmView(session: session) { freed in
                              sessionFreed = freed
                              if freed > 0 { phase = .done } else { phase = .empty }
                          } onContinueSwiping: {
                              phase = .swiping
                          }
        case .done:       doneScreen
        case .empty:      emptyScreen
        }
    }

    // MARK: - Loading

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

    // MARK: - Done (after delete)

    private var doneScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.bounce, value: sessionFreed)
            VStack(spacing: 8) {
                Text("Freed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PulseColor.textSecondary)
                Text(ByteCountFormatter.string(fromByteCount: sessionFreed, countStyle: .file))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .monospacedDigit()
            }
            Text("Your phone has a bit more room. Want to keep going?")
                .font(.system(size: 15))
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
            PrimaryButton(title: "Sweep again", systemImage: "arrow.clockwise") {
                Task { await restart() }
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 24)
        }
        .onAppear { Haptics.success() }
    }

    // MARK: - Empty (no candidates found)

    private var emptyScreen: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(PulseColor.excellent)
            Text("All clear ✨")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(PulseColor.textPrimary)
            Text("Nothing obvious to clean right now. Check back after you've taken more photos.")
                .font(.system(size: 15))
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Actions

    private func start() async {
        if queue.state == .idle { await queue.load() }
        switch queue.state {
        case .denied:
            phase = .denied
        case .ready:
            if queue.assets.isEmpty {
                phase = .empty
            } else {
                session.load(queue.assets)
                phase = .swiping
            }
        default:
            phase = .loading
        }
    }

    private func restart() async {
        queue = PhotoQueue()
        session = SwipeSession()
        sessionFreed = 0
        phase = .loading
        await start()
    }
}
