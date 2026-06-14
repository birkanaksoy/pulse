import SwiftUI
import Photos

struct BurstsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var detector = BurstDetector()
    @State private var presented: BurstGroup?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                header
                if detector.isScanning {
                    ProgressView().tint(PulseColor.blue500).frame(maxWidth: .infinity).padding(.vertical, PulseSpace.xxxl)
                } else if detector.groups.isEmpty {
                    empty
                } else {
                    summary
                    ForEach(detector.groups) { g in
                        groupCard(g)
                    }
                }
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("Burst photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .task { if detector.groups.isEmpty { await detector.scan() } }
        .sheet(item: $presented) { g in
            NavigationStack {
                PhotoGridView(
                    assets: g.assets,
                    preselectedSkipFirst: true,
                    title: "Burst",
                    onDelete: { _ in detector.consume(g) }
                )
            }
            .pulseSheet()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Burst photos")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("iOS bursts a dozen shots in a second. The keeper is usually one of them.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var empty: some View {
        VStack(spacing: PulseSpace.m) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(PulseColor.blue500)
            Text("No bursts found")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Take a burst with the shutter held down — Pulse will group them here.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulseSpace.xxxl)
    }

    private var summary: some View {
        HStack {
            Text("Potential savings").font(PulseFont.callout).foregroundStyle(PulseColor.textSecondary)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: detector.totalSavings, countStyle: .file))
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.blue500)
        }
        .pulseCard()
    }

    private func groupCard(_ g: BurstGroup) -> some View {
        Button { presented = g } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(g.assets.count) shots")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Save \(ByteCountFormatter.string(fromByteCount: g.savings, countStyle: .file))")
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.card)
    }
}
