import SwiftUI

struct SmartAlertsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var masterOn: Bool = SmartNotificationEngine.masterEnabled
    @State private var enabled: [SmartNotificationEngine.Category: Bool] = [:]
    @State private var notifAuthorized = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                masterCard
                if masterOn { categoriesCard }
                Text("All alerts are local. Nothing leaves your phone. Smart alerts are sent only after a scan you ran.")
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textTertiary)
                    .padding(.horizontal, PulseSpace.s)
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("Smart Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .task {
            for c in SmartNotificationEngine.Category.allCases {
                enabled[c] = SmartNotificationEngine.categoryEnabled(c)
            }
            let s = await NotificationScheduler.currentStatus()
            notifAuthorized = (s == .authorized || s == .provisional)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Smart Alerts")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Triggered local notifications — only when something matters.")
                .font(PulseFont.callout)
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    private var masterCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: masterBinding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable smart alerts")
                        .font(PulseFont.body)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text(notifAuthorized
                         ? String(localized: "Permission granted at the OS level.")
                         : String(localized: "Tap to request permission."))
                        .font(PulseFont.footnote)
                        .foregroundStyle(PulseColor.textTertiary)
                }
            }
            .tint(PulseColor.blue500)
            .padding(.vertical, PulseSpace.m)
        }
        .pulseCard()
    }

    private var categoriesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(SmartNotificationEngine.Category.allCases.enumerated()), id: \.element) { idx, c in
                if idx > 0 { Divider().background(PulseColor.stroke) }
                Toggle(isOn: binding(for: c)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.displayName)
                            .font(PulseFont.body)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text(c.displayDescription)
                            .font(PulseFont.footnote)
                            .foregroundStyle(PulseColor.textTertiary)
                    }
                }
                .tint(PulseColor.blue500)
                .padding(.vertical, PulseSpace.m)
            }
        }
        .pulseCard()
    }

    private var masterBinding: Binding<Bool> {
        Binding(
            get: { masterOn },
            set: { new in
                Haptics.tap()
                if new {
                    Task {
                        let granted = await NotificationScheduler.requestAuthorization()
                        notifAuthorized = granted
                        if granted {
                            masterOn = true
                            SmartNotificationEngine.masterEnabled = true
                        } else {
                            masterOn = false
                        }
                    }
                } else {
                    masterOn = false
                    SmartNotificationEngine.masterEnabled = false
                }
            }
        )
    }

    private func binding(for c: SmartNotificationEngine.Category) -> Binding<Bool> {
        Binding(
            get: { enabled[c] ?? true },
            set: { new in
                Haptics.tap(0.3)
                enabled[c] = new
                SmartNotificationEngine.setCategory(c, enabled: new)
            }
        )
    }
}
