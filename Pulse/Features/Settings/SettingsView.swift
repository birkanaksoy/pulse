import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.modelContext) private var context
    @State private var showingPaywall = false
    @State private var showingDeleteConfirm = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingIconPicker = false
    @AppStorage("pulse.weeklyReminder") private var weeklyReminder = false
    @State private var notifAuthorized = false

    var body: some View {
        ZStack {
            AmbientBackground(tint: PulseColor.blue500)
            ScrollView {
                VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                    Text("Settings")
                        .font(PulseFont.titleXL)
                        .foregroundStyle(PulseColor.textPrimary)

                if !entitlements.isPro {
                    proBanner
                }

                section("Appearance") {
                    button("App Icon") { showingIconPicker = true }
                }

                section("Reminders") {
                    Toggle(isOn: weeklyToggleBinding) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly check-in")
                                .font(PulseFont.body)
                                .foregroundStyle(PulseColor.textPrimary)
                            Text("Every Sunday at 10:00 — a nudge to run a fresh scan.")
                                .font(PulseFont.footnote)
                                .foregroundStyle(PulseColor.textTertiary)
                        }
                    }
                    .tint(PulseColor.blue500)
                    .padding(.vertical, PulseSpace.s)
                }

                section("Account") {
                    row("Pulse Pro", trailing: entitlements.isPro ? "Active" : "Free")
                    Divider().background(PulseColor.stroke)
                    button("Restore Purchases") { Task { await entitlements.restore() } }
                    Divider().background(PulseColor.stroke)
                    button("Toggle Pro (dev)") { entitlements.devTogglePro() }
                }

                section("Privacy") {
                    row("On-device analysis", trailing: "Always")
                    Divider().background(PulseColor.stroke)
                    row("Diagnostics shared", trailing: "Never")
                    Divider().background(PulseColor.stroke)
                    button("Delete all data") { showingDeleteConfirm = true }
                }

                section("About") {
                    row("Version", trailing: "0.1.0")
                    Divider().background(PulseColor.stroke)
                    button("Privacy Policy") { showingPrivacy = true }
                    Divider().background(PulseColor.stroke)
                    button("Terms of Use") { showingTerms = true }
                    Divider().background(PulseColor.stroke)
                    button("Support") {
                        if let url = URL(string: "mailto:support@pulseapp.app") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.l)
            .padding(.bottom, PulseSpace.xxxl)
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView().pulseSheet() }
        .sheet(isPresented: $showingTerms)   { NavigationStack { LegalView(kind: .terms) }.pulseSheet() }
        .sheet(isPresented: $showingPrivacy) { NavigationStack { LegalView(kind: .privacy) }.pulseSheet() }
        .sheet(isPresented: $showingIconPicker) { NavigationStack { AppIconPicker() }.pulseSheet() }
        .confirmationDialog(
            "Delete all Pulse data?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete everything", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every scan record, the widget snapshot, and the weekly reminder. Onboarding stays done. This cannot be undone.")
        }
        .task {
            let status = await NotificationScheduler.currentStatus()
            notifAuthorized = (status == .authorized || status == .provisional)
        }
    }

    private func deleteAllData() {
        // Scan records
        let descriptor = FetchDescriptor<ScanRecord>()
        if let all = try? context.fetch(descriptor) {
            for r in all { context.delete(r) }
            try? context.save()
        }
        // Widget snapshot
        if let defaults = UserDefaults(suiteName: SharedScoreStore.suiteName) {
            defaults.removeObject(forKey: "pulse.snapshot")
        }
        // Notifications
        NotificationScheduler.cancelWeeklyReminder()
        weeklyReminder = false
        // Refresh widget
        WidgetCenter.shared.reloadAllTimelines()
        Haptics.success()
    }

    private var weeklyToggleBinding: Binding<Bool> {
        Binding(
            get: { weeklyReminder },
            set: { new in
                Haptics.tap()
                if new {
                    Task {
                        let granted = await NotificationScheduler.requestAuthorization()
                        notifAuthorized = granted
                        if granted {
                            NotificationScheduler.scheduleWeeklyReminder()
                            weeklyReminder = true
                        } else {
                            weeklyReminder = false
                        }
                    }
                } else {
                    NotificationScheduler.cancelWeeklyReminder()
                    weeklyReminder = false
                }
            }
        )
    }

    private var proBanner: some View {
        Button { showingPaywall = true } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white.opacity(0.2)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Pulse Pro")
                        .font(PulseFont.titleM)
                        .foregroundStyle(.white)
                    Text("Deeper diagnostics. Unlimited Doctor.")
                        .font(PulseFont.callout)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white)
            }
            .padding(PulseSpace.xl)
            .background(
                RoundedRectangle(cornerRadius: PulseRadius.card, style: .continuous)
                    .fill(PulseColor.ringGradient)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: PulseSpace.s) {
            Text(title.uppercased())
                .font(PulseFont.footnote.weight(.semibold))
                .foregroundStyle(PulseColor.textTertiary)
                .tracking(0.6)
            VStack(spacing: 0) { content() }.pulseCard()
        }
    }

    private func row(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
            Spacer()
            Text(trailing).font(PulseFont.body).foregroundStyle(PulseColor.textSecondary)
        }
        .padding(.vertical, PulseSpace.m)
    }

    private func button(_ title: String, action: @escaping () -> Void) -> some View {
        let isDestructive = title.localizedCaseInsensitiveContains("delete")
        return Button(action: action) {
            HStack {
                Text(title)
                    .font(PulseFont.body)
                    .foregroundStyle(isDestructive ? PulseColor.critical : PulseColor.blue500)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .padding(.vertical, PulseSpace.m)
        }
        .buttonStyle(.plain)
    }
}
