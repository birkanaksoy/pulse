import SwiftUI

/// Drop-in snackbar with an "Undo" action that auto-dismisses after a delay.
struct UndoSnackbar: View {
    var message: LocalizedStringKey
    var undoLabel: LocalizedStringKey = "Undo"
    var onUndo: () -> Void
    var onDismiss: () -> Void

    @State private var timer: Task<Void, Never>?

    var body: some View {
        HStack(spacing: PulseSpace.m) {
            Text(message)
                .font(PulseFont.callout)
                .foregroundStyle(.white)
            Spacer()
            Button {
                timer?.cancel()
                Haptics.tap()
                onUndo()
                onDismiss()
            } label: {
                Text(undoLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PulseColor.blue300)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PulseSpace.l)
        .padding(.vertical, PulseSpace.m)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .padding(.horizontal, PulseSpace.l)
        .onAppear {
            timer = Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                if !Task.isCancelled { onDismiss() }
            }
        }
        .onDisappear { timer?.cancel() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
