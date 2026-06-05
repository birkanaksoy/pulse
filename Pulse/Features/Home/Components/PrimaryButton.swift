import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = "arrow.right"
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap(0.5)
            action()
        }) {
            HStack(spacing: PulseSpace.s) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    if let s = systemImage {
                        Image(systemName: s)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: PulseRadius.button, style: .continuous)
                    .fill(PulseColor.ringGradient)
            )
            .shadow(color: PulseColor.blue500.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
