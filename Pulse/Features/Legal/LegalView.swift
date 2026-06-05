import SwiftUI

struct LegalView: View {
    enum Kind { case privacy, terms }

    @Environment(\.dismiss) private var dismiss
    var kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.l) {
                Text(title)
                    .font(PulseFont.titleXL)
                    .foregroundStyle(PulseColor.textPrimary)
                Text("Last updated: 5 June 2026")
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textTertiary)

                ForEach(Array(sections.enumerated()), id: \.offset) { _, s in
                    VStack(alignment: .leading, spacing: PulseSpace.s) {
                        Text(s.heading)
                            .font(PulseFont.titleM)
                            .foregroundStyle(PulseColor.textPrimary)
                        Text(s.body)
                            .font(PulseFont.body)
                            .foregroundStyle(PulseColor.textSecondary)
                    }
                }
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(PulseColor.canvas.ignoresSafeArea())
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
    }

    private struct Section { var heading: String; var body: String }

    private var title: String {
        switch kind {
        case .privacy: return String(localized: "Privacy Policy")
        case .terms:   return String(localized: "Terms of Use")
        }
    }
    private var navTitle: String {
        switch kind {
        case .privacy: return String(localized: "Privacy")
        case .terms:   return String(localized: "Terms")
        }
    }

    private var sections: [Section] {
        switch kind {
        case .privacy: return privacySections
        case .terms:   return termsSections
        }
    }

    private var privacySections: [Section] {[
        Section(
            heading: String(localized: "Everything runs on your device"),
            body: String(localized: "Pulse performs every measurement locally using iOS APIs. Storage, thermal state, battery level, charging state, Low Power Mode, photo counts — all of this is read by your iPhone and stays on it. Nothing is uploaded.")
        ),
        Section(
            heading: String(localized: "What we never collect"),
            body: String(localized: "No analytics SDK, no advertising identifier, no crash-reporting third party, no usage tracking. We do not ask for your email or any account.")
        ),
        Section(
            heading: String(localized: "Photo Library access"),
            body: String(localized: "If you grant Photo Library access, Pulse reads only metadata (counts and file sizes) to populate the Clean tab. Your photos and videos never leave your device.")
        ),
        Section(
            heading: String(localized: "Subscriptions"),
            body: String(localized: "Pulse Pro is handled by Apple via StoreKit. We receive only an entitlement flag (Pro: yes/no) from Apple — never your payment details.")
        ),
        Section(
            heading: String(localized: "Notifications"),
            body: String(localized: "If you enable the weekly check-in, Pulse schedules a local notification on your device. No notification content leaves the phone.")
        ),
        Section(
            heading: String(localized: "Your control"),
            body: String(localized: "Settings → Privacy → Delete all data wipes every scan record, the widget snapshot, and the weekly reminder in one step.")
        ),
        Section(
            heading: String(localized: "Contact"),
            body: String(localized: "Questions about privacy? Email support@pulseapp.app.")
        ),
    ]}

    private var termsSections: [Section] {[
        Section(
            heading: String(localized: "Use of the app"),
            body: String(localized: "Pulse is provided to help you monitor your phone's health. The Pulse Score and personality labels are interpretive summaries of real iOS signals — informational, not medical or diagnostic guarantees.")
        ),
        Section(
            heading: String(localized: "Honesty about iOS limits"),
            body: String(localized: "iOS does not expose true battery health, per-app storage usage, or precise temperature to third-party apps. Pulse shows only what iOS publishes and clearly marks anything outside that scope.")
        ),
        Section(
            heading: String(localized: "Pulse Pro subscription"),
            body: String(localized: "Subscriptions auto-renew at the end of each billing period unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID. Manage or cancel anytime in your App Store account.")
        ),
        Section(
            heading: String(localized: "No file deletion"),
            body: String(localized: "Pulse never deletes photos, videos, or files on its own. Every cleanup action opens the relevant Apple app or Settings so you stay in control.")
        ),
        Section(
            heading: String(localized: "Liability"),
            body: String(localized: "Pulse is provided “as is”. We are not liable for decisions you make based on the score, including device repair or replacement choices.")
        ),
        Section(
            heading: String(localized: "Changes"),
            body: String(localized: "We may update these terms. Material changes are announced in the app before they take effect.")
        ),
    ]}
}
