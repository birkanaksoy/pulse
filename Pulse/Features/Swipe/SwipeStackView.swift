import SwiftUI
import Photos

/// Tinder-style stack of photo cards. Swipe left = mark for delete,
/// swipe right = keep. Stops when the queue runs out.
struct SwipeStackView: View {
    @Bindable var session: SwipeSession
    var onFinish: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var isAnimatingOut = false

    /// Distance (points) the user must drag past for the swipe to "commit".
    private let commitThreshold: CGFloat = 110

    var body: some View {
        VStack(spacing: 18) {
            topBar
            ZStack {
                if session.currentAsset == nil && session.nextAsset == nil {
                    Color.clear
                        .onAppear { onFinish() }
                }
                if let next = session.nextAsset {
                    cardView(for: next)
                        .id("next-\(next.localIdentifier)")
                        .scaleEffect(0.94)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                }
                if let current = session.currentAsset {
                    cardView(for: current)
                        .id("current-\(current.localIdentifier)")
                        .offset(dragOffset)
                        .rotationEffect(.degrees(dragRotation))
                        .overlay(directionStamp)
                        .gesture(dragGesture)
                        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: dragOffset)
                }
            }
            actionRow
            footer
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(PulseColor.canvas.ignoresSafeArea())
    }

    // MARK: - Card view (constrained to a nice aspect)

    @ViewBuilder
    private func cardView(for asset: PHAsset) -> some View {
        PhotoCardView(asset: asset)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, y: 12)
            .frame(maxWidth: .infinity)
            .aspectRatio(3 / 4, contentMode: .fit)
    }

    // MARK: - Direction stamp (DELETE / KEEP overlay during drag)

    @ViewBuilder
    private var directionStamp: some View {
        let progress = min(1, abs(dragOffset.width) / commitThreshold)
        if progress > 0.2 {
            let leaning: SwipeSession.Decision = dragOffset.width < 0 ? .delete : .keep
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(stampColor(for: leaning).opacity(0.18 * progress))
                Text(stampText(for: leaning))
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(stampColor(for: leaning), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .rotationEffect(.degrees(leaning == .delete ? -18 : 18))
                    .opacity(progress)
            }
            .allowsHitTesting(false)
        }
    }

    private func stampColor(for d: SwipeSession.Decision) -> Color {
        d == .delete ? PulseColor.critical : PulseColor.excellent
    }
    private func stampText(for d: SwipeSession.Decision) -> String {
        d == .delete ? String(localized: "DELETE").uppercased() : String(localized: "KEEP").uppercased()
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: { session.undo(); Haptics.tap(0.3) }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(session.history.isEmpty ? PulseColor.textTertiary : PulseColor.textPrimary)
                        .padding(10)
                        .background(Circle().fill(PulseColor.muted))
                }
                .disabled(session.history.isEmpty)
                Spacer()
                VStack(spacing: 0) {
                    Text("\(session.currentIndex) / \(session.assets.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulseColor.textPrimary)
                        .monospacedDigit()
                    Text("swiped")
                        .font(.system(size: 11))
                        .foregroundStyle(PulseColor.textTertiary)
                }
                Spacer()
                Button(action: onFinish) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PulseColor.blue500)
                        .padding(10)
                        .background(Circle().fill(PulseColor.blue50))
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PulseColor.stroke).frame(height: 4)
                    Capsule()
                        .fill(PulseColor.ringGradient)
                        .frame(width: proxy.size.width * session.progress, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: session.progress)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 22) {
            actionButton(icon: "xmark", tint: PulseColor.critical, accessibilityLabel: "Delete") {
                commit(.delete)
            }
            counterChip
            actionButton(icon: "checkmark", tint: PulseColor.excellent, accessibilityLabel: "Keep") {
                commit(.keep)
            }
        }
    }

    private func actionButton(icon: String, tint: Color, accessibilityLabel: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [PulseColor.card, PulseColor.card.opacity(0.92)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [tint.opacity(0.5), tint.opacity(0.2)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 68, height: 68)
            .shadow(color: tint.opacity(0.30), radius: 14, y: 6)
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var counterChip: some View {
        VStack(spacing: 0) {
            Text(ByteCountFormatter.string(fromByteCount: session.pendingBytes, countStyle: .file))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(PulseColor.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("ready to free")
                .font(.system(size: 11))
                .foregroundStyle(PulseColor.textTertiary)
        }
        .frame(minWidth: 96)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw").font(.system(size: 11))
            Text("Swipe left to delete, right to keep")
                .font(.system(size: 11))
        }
        .foregroundStyle(PulseColor.textTertiary)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                dragRotation = Double(value.translation.width / 18)
            }
            .onEnded { value in
                if value.translation.width < -commitThreshold {
                    flyAway(.delete)
                } else if value.translation.width > commitThreshold {
                    flyAway(.keep)
                } else {
                    dragOffset = .zero
                    dragRotation = 0
                }
            }
    }

    private func flyAway(_ d: SwipeSession.Decision) {
        guard !isAnimatingOut else { return }
        isAnimatingOut = true
        Haptics.tap(0.4)
        let xTarget: CGFloat = d == .delete ? -600 : 600
        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = CGSize(width: xTarget, height: dragOffset.height)
            dragRotation = d == .delete ? -25 : 25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            session.decide(d)
            // Reset offset WITHOUT animation so the new card doesn't slide in.
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                dragOffset = .zero
                dragRotation = 0
            }
            isAnimatingOut = false
            if session.isFinished { onFinish() }
        }
    }

    private func commit(_ d: SwipeSession.Decision) {
        flyAway(d)
    }
}
