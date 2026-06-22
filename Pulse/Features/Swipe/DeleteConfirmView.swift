import SwiftUI
import Photos

/// End-of-session summary: shows the count + bytes pending, with a big
/// "Delete X items" button that calls PhotoCleaner. iOS prompts confirmation.
struct DeleteConfirmView: View {
    var session: SwipeSession
    var onDone: (Int64) -> Void
    var onContinueSwiping: () -> Void

    @State private var deleting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            hero
            stats
            Spacer()
            buttons
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: session.marked.isEmpty ? "checkmark.seal.fill" : "trash.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    session.marked.isEmpty ? PulseColor.excellent : PulseColor.critical
                )
            Text(session.marked.isEmpty ? "Nothing marked" : "Ready to delete")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(PulseColor.textPrimary)
        }
    }

    private var stats: some View {
        VStack(spacing: 12) {
            statRow(label: "Marked", value: "\(session.marked.count)")
            statRow(label: "Kept", value: "\(session.kept.count)")
            statRow(
                label: "Space to free",
                value: ByteCountFormatter.string(fromByteCount: session.pendingBytes, countStyle: .file)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(PulseColor.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(PulseColor.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }

    private func statRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(PulseColor.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(PulseColor.textPrimary)
                .monospacedDigit()
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            if !session.marked.isEmpty {
                Button {
                    Task { await doDelete() }
                } label: {
                    HStack(spacing: 8) {
                        if deleting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .bold))
                            Text("Delete \(session.marked.count) items")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(PulseColor.critical)
                    )
                    .shadow(color: PulseColor.critical.opacity(0.4), radius: 18, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(deleting)
            }

            // Only show "Keep swiping" if there are still assets to swipe.
            if !session.isFinished {
                Button(action: onContinueSwiping) {
                    Text("Keep swiping")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PulseColor.blue500)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(PulseColor.blue50)
                        )
                }
                .buttonStyle(.plain)
            }

            // If nothing was marked, give the user a graceful exit.
            if session.marked.isEmpty {
                Button {
                    onDone(0)
                } label: {
                    Text("All done")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PulseColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @MainActor
    private func doDelete() async {
        guard !session.marked.isEmpty else { return }
        deleting = true
        let result = await PhotoCleaner.delete(session.marked)
        deleting = false
        if result.success {
            Haptics.success()
            // Hand the real freed-byte count straight to the parent.
            onDone(result.freed)
        }
        // If the user cancelled iOS's confirmation, stay on this screen.
    }
}
