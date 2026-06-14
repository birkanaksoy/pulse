import SwiftUI

struct PrimaryButton: View {
    var title: LocalizedStringKey
    var systemImage: String? = "arrow.right"
    var isLoading: Bool = false
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.tap(0.5)
            action()
        } label: {
            HStack(spacing: PulseSpace.s) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    if let s = systemImage {
                        Image(systemName: s)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(.white)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: PulseRadius.button, style: .continuous)
                        .fill(PulseColor.ringGradient)
                    // Top highlight for depth
                    RoundedRectangle(cornerRadius: PulseRadius.button, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.20), .white.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.overlay)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: PulseRadius.button, style: .continuous)
                    .strokeBorder(.white.opacity(0.30), lineWidth: 0.5)
            )
            .shadow(color: PulseColor.blue500.opacity(0.45), radius: 18, y: 10)
            .scaleEffect(pressed && !reduceMotion ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !pressed { pressed = true } }
                .onEnded { _ in pressed = false }
        )
    }
}
