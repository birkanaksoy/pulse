import SwiftUI

struct MagicCleanupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cleanup = MagicCleanup()
    @State private var animatedFreed: Double = 0

    var body: some View {
        ZStack {
            AmbientBackground(tint: tintForPhase)
            content
        }
        .navigationTitle("Magic Cleanup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .task { if case .idle = cleanup.phase { await cleanup.analyze() } }
    }

    private var tintForPhase: Color {
        switch cleanup.phase {
        case .done:       return PulseColor.excellent
        case .cleaning:   return PulseColor.purple
        default:          return PulseColor.blue500
        }
    }

    @ViewBuilder
    private var content: some View {
        switch cleanup.phase {
        case .idle:                                analyzingScreen(progress: 0, stage: "Starting…")
        case .analyzing(let p, let s):             analyzingScreen(progress: p, stage: s)
        case .ready(let plan):                     readyScreen(plan: plan)
        case .cleaning(let p, let s, let freed):   cleaningScreen(progress: p, stage: s, freed: freed)
        case .done(let freed):                     doneScreen(freed: freed)
        }
    }

    // MARK: - Analyzing

    private func analyzingScreen(progress: Double, stage: String) -> some View {
        VStack(spacing: PulseSpace.xl) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(PulseColor.stroke, lineWidth: 14)
                    .frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(PulseColor.ringGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                    .animation(.easeInOut(duration: 0.4), value: progress)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(PulseColor.ringGradient)
            }
            VStack(spacing: 8) {
                Text("Scanning your library…")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                Text(stage)
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
                    .animation(.easeInOut, value: stage)
            }
            Spacer()
        }
        .padding(PulseSpace.xl)
    }

    // MARK: - Ready (preview)

    private func readyScreen(plan: MagicCleanup.Plan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                heroSavings(plan: plan)
                breakdown(plan: plan)
                if !plan.isEmpty {
                    PrimaryButton(title: "Clean it all", systemImage: "wand.and.stars") {
                        Task { await cleanup.execute(plan: plan) }
                    }
                }
                Text("iOS will ask you to confirm each batch. Nothing is deleted without your tap.")
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textTertiary)
                    .padding(.horizontal, PulseSpace.s)
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
    }

    private func heroSavings(plan: MagicCleanup.Plan) -> some View {
        VStack(alignment: .leading, spacing: PulseSpace.s) {
            if plan.isEmpty {
                Text("You're already clean ✨")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(PulseColor.textPrimary)
                Text("No duplicates, no bursts, no oversized videos. Nice.")
                    .font(PulseFont.body)
                    .foregroundStyle(PulseColor.textSecondary)
            } else {
                Text("We can free up")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
                Text(ByteCountFormatter.string(fromByteCount: plan.totalSavings, countStyle: .file))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(PulseColor.ringGradient)
                    .monospacedDigit()
                    .kerning(-1.5)
                Text("Across \(plan.deletableCount + plan.convertibleCount) items.")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCard(elevated: true)
    }

    private func breakdown(plan: MagicCleanup.Plan) -> some View {
        VStack(spacing: PulseSpace.m) {
            row(icon: "rectangle.stack.badge.minus",
                title: "Duplicate photos",
                count: plan.duplicates.count,
                bytes: plan.duplicates.reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) })
            row(icon: "camera.aperture",
                title: "Burst extras",
                count: plan.bursts.count,
                bytes: plan.bursts.reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) })
            row(icon: "film",
                title: "Big videos",
                count: plan.largeVideos.count,
                bytes: plan.largeVideos.reduce(into: Int64(0)) { $0 += PhotoCleaner.bytes(of: $1) })
            row(icon: "livephoto",
                title: "Live Photos to convert",
                count: plan.convertibleCount,
                bytes: plan.convertibleBytes)
        }
    }

    private func row(icon: String, title: LocalizedStringKey, count: Int, bytes: Int64) -> some View {
        HStack(spacing: PulseSpace.m) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(PulseColor.ringGradient, in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
                Text(count > 0 ? "\(count) items" : "None found")
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textTertiary)
            }
            Spacer()
            Text(count > 0 ? ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) : "—")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(count > 0 ? PulseColor.blue500 : PulseColor.textTertiary)
                .monospacedDigit()
        }
        .pulseCard(padding: PulseSpace.m)
    }

    // MARK: - Cleaning

    private func cleaningScreen(progress: Double, stage: String, freed: Int64) -> some View {
        VStack(spacing: PulseSpace.xl) {
            Spacer()
            ZStack {
                Circle().stroke(PulseColor.stroke, lineWidth: 14).frame(width: 220, height: 220)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [PulseColor.purple, PulseColor.blue500],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 220, height: 220)
                    .animation(.easeInOut(duration: 0.4), value: progress)
                VStack(spacing: 4) {
                    Text(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(PulseColor.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("freed")
                        .font(PulseFont.footnote)
                        .foregroundStyle(PulseColor.textTertiary)
                }
            }
            Text(stage)
                .font(PulseFont.body)
                .foregroundStyle(PulseColor.textSecondary)
                .animation(.easeInOut, value: stage)
            Spacer()
        }
        .padding(PulseSpace.xl)
    }

    // MARK: - Done (the wow moment)

    private func doneScreen(freed: Int64) -> some View {
        ZStack {
            ConfettiBurst()

            VStack(spacing: PulseSpace.l) {
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [PulseColor.excellent, PulseColor.blue500],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .symbolEffect(.bounce, value: freed)
                Text("Freed")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textSecondary)
                Text(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [PulseColor.excellent, PulseColor.teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .monospacedDigit()
                    .kerning(-2)
                    .contentTransition(.numericText(value: Double(freed)))
                Text(funMessage(freed: freed))
                    .font(PulseFont.body)
                    .foregroundStyle(PulseColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PulseSpace.xl)
                Spacer()
                PrimaryButton(title: "All done", systemImage: "checkmark") {
                    Haptics.success()
                    dismiss()
                }
                .padding(.horizontal, PulseSpace.xl)
                Spacer().frame(height: PulseSpace.xxl)
            }
        }
        .onAppear { Haptics.success() }
    }

    private func funMessage(freed: Int64) -> String {
        let mb = Double(freed) / (1024 * 1024)
        if mb >= 5000 { return String(localized: "That's roughly 1,200 photos of breathing room. Nice work.") }
        if mb >= 1000 { return String(localized: "That's about 250 photos worth. Your phone thanks you.") }
        if mb >= 100  { return String(localized: "Tidy. Your phone has a little more room to think.") }
        if mb > 0     { return String(localized: "Every byte counts.") }
        return String(localized: "Nothing to delete. You're already running clean.")
    }
}
