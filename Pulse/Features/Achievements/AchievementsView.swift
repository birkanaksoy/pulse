import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlements
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    private var achievements: [Achievement] {
        let streak = StreakTracker.compute(records)
        return AchievementsEngine.compute(records: records, streak: streak, isPro: entitlements.isPro)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: PulseSpace.l),
                              GridItem(.flexible(), spacing: PulseSpace.l)],
                    spacing: PulseSpace.l
                ) {
                    ForEach(achievements) { item in
                        AchievementCell(item: item)
                    }
                }
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            let unlocked = achievements.filter(\.unlocked).count
            Text("Achievements")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("\(unlocked) of \(achievements.count) unlocked")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }
}

struct AchievementCell: View {
    var item: Achievement

    var body: some View {
        VStack(spacing: PulseSpace.s) {
            ZStack {
                Circle()
                    .fill(item.unlocked
                          ? AnyShapeStyle(PulseColor.ringGradient)
                          : AnyShapeStyle(PulseColor.muted))
                    .frame(width: 64, height: 64)
                Image(systemName: item.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(item.unlocked ? .white : PulseColor.textTertiary)
                    .symbolEffect(.bounce, value: item.unlocked)
            }
            .shadow(color: item.unlocked ? PulseColor.blue500.opacity(0.3) : .clear,
                    radius: 10, y: 4)

            Text(item.title)
                .font(PulseFont.titleM)
                .foregroundStyle(item.unlocked ? PulseColor.textPrimary : PulseColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.detail)
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if !item.unlocked && item.progress > 0 {
                ProgressView(value: item.progress)
                    .progressViewStyle(.linear)
                    .tint(PulseColor.blue500)
                    .frame(width: 60)
                    .padding(.top, 2)
            }
        }
        .padding(PulseSpace.l)
        .frame(maxWidth: .infinity)
        .pulseCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.title))
        .accessibilityValue(Text(item.unlocked ? "Unlocked" : "Locked, \(Int(item.progress * 100))%"))
    }
}
