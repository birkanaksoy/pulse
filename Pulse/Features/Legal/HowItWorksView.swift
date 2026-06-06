import SwiftUI

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                Text("How Pulse works")
                    .font(PulseFont.titleXL)
                    .foregroundStyle(PulseColor.textPrimary)
                Text("Every number you see is read from iOS itself. We never guess, never round up, and never invent metrics to look impressive.")
                    .font(PulseFont.body)
                    .foregroundStyle(PulseColor.textSecondary)

                section(
                    title: "The Pulse Score (0–100)",
                    body: "Storage pressure × 55% + thermal state × 45%. Both signals come directly from iOS — `volumeAvailableCapacityKey` for storage, `ProcessInfo.thermalState` for thermal. The weights are documented in our source code and never change without an app update."
                )
                section(
                    title: "What we measure honestly",
                    body: "• Storage used % — matches iPhone Storage in Settings.\n• Thermal state — same buckets iOS uses to decide when to throttle: nominal · fair · serious · critical.\n• Battery level + charging state + Low Power Mode — read from UIDevice and ProcessInfo.\n• Photo / video / screenshot counts and real GB — from PhotoKit asset resources, computed on-device."
                )
                section(
                    title: "What iOS hides — and we don't fake",
                    body: "• True battery health % is private to Apple. We show your current charge and link to Settings → Battery → Battery Health.\n• Per-app storage usage is private. We link to iPhone Storage for a breakdown.\n• Precise temperature in °C/°F is private. We show the coarse thermal state iOS itself uses."
                )
                section(
                    title: "What we never do",
                    body: "• Upload anything to a server.\n• Use third-party analytics or trackers.\n• Delete files on our own — every cleanup opens the relevant Apple app.\n• Read your photos themselves — only metadata (counts, file sizes)."
                )
                section(
                    title: "Verify it yourself",
                    body: "Pulse is open source. Read the math, audit the probes, run it locally:\nhttps://github.com/birkanaksoy/pulse"
                )
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("How it works")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
    }

    private func section(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: PulseSpace.s) {
            Text(title)
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Text(body)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
        }
        .padding(.top, PulseSpace.s)
    }
}
