import SwiftUI
import SwiftData
import UIKit

struct StorageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var records: [ScanRecord]

    @State private var reading: StorageReading = StorageReading(totalBytes: 0, freeBytes: 0)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                hero
                breakdown
                trendCard
                settingsLink
                disclaimer
            }
            .padding(.horizontal, PulseSpace.xl)
            .padding(.top, PulseSpace.l)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(PulseColor.muted.ignoresSafeArea())
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .onAppear { reading = StorageProbe().read() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Storage")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Reported directly by iOS — these numbers are real.")
                .font(PulseFont.footnote)
                .foregroundStyle(PulseColor.textTertiary)
        }
    }

    private var hero: some View {
        HStack(spacing: PulseSpace.l) {
            ZStack {
                Circle().stroke(PulseColor.stroke, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: Double(reading.usedPercent) / 100.0)
                    .stroke(PulseColor.ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(reading.usedPercent)%")
                        .font(PulseFont.titleL)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("Used")
                        .font(PulseFont.footnote)
                        .foregroundStyle(PulseColor.textTertiary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: PulseSpace.s) {
                kv("Total",     bytes(reading.totalBytes))
                kv("Free",      bytes(reading.freeBytes))
                kv("In use",    bytes(reading.totalBytes - reading.freeBytes))
            }
            Spacer()
        }
        .pulseCard()
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Status")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            HStack(spacing: PulseSpace.m) {
                Image(systemName: statusIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(statusColor.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusLabel)
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text(statusSubtitle)
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
            }
        }
        .pulseCard()
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: PulseSpace.m) {
            Text("Used % over recent scans")
                .font(PulseFont.titleM)
                .foregroundStyle(PulseColor.textPrimary)
            let values = records.prefix(14).reversed().map { $0.storageUsed }
            if values.count < 2 {
                Text("Run more scans to build a trend.")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                MiniBars(values: Array(values))
                    .frame(height: 80)
            }
        }
        .pulseCard()
    }

    private var settingsLink: some View {
        Button {
            if let url = URL(string: "App-Prefs:General&path=STORAGE_MGMT_SETTINGS") {
                UIApplication.shared.open(url)
            } else if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: PulseSpace.m) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PulseColor.blue500)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(PulseColor.blue50))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open iPhone Storage")
                        .font(PulseFont.titleM)
                        .foregroundStyle(PulseColor.textPrimary)
                    Text("See per-app breakdown in Settings.")
                        .font(PulseFont.callout)
                        .foregroundStyle(PulseColor.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PulseColor.textTertiary)
            }
            .pulseCard()
        }
        .buttonStyle(.plain)
    }

    private var disclaimer: some View {
        Text("Apps cannot read per-app storage usage on iOS. For an app-level breakdown, use iPhone Storage in Settings.")
            .font(PulseFont.footnote)
            .foregroundStyle(PulseColor.textTertiary)
            .padding(.horizontal, PulseSpace.s)
    }

    // MARK: - Derived

    private var statusIcon: String {
        switch reading.usedPercent {
        case ..<60:  return "checkmark.circle.fill"
        case ..<80:  return "exclamationmark.circle"
        case ..<90:  return "exclamationmark.triangle"
        default:     return "exclamationmark.octagon.fill"
        }
    }
    private var statusColor: Color {
        switch reading.usedPercent {
        case ..<60:  return PulseColor.excellent
        case ..<80:  return PulseColor.good
        case ..<90:  return PulseColor.fair
        default:     return PulseColor.critical
        }
    }
    private var statusLabel: String {
        switch reading.usedPercent {
        case ..<60:  return "Plenty of room"
        case ..<80:  return "Comfortable"
        case ..<90:  return "Getting tight"
        default:     return "Nearly full"
        }
    }
    private var statusSubtitle: String {
        switch reading.usedPercent {
        case ..<60:  return "iOS performs best below 80% used."
        case ..<80:  return "Still healthy. Watch the trend."
        case ..<90:  return "Consider clearing photos or unused apps."
        default:     return "Updates and Camera may fail above 90%."
        }
    }

    // MARK: - Helpers

    private func bytes(_ b: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: max(0, b), countStyle: .file)
    }

    private func kv(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(k).font(PulseFont.footnote).foregroundStyle(PulseColor.textTertiary)
            Text(v).font(PulseFont.body).foregroundStyle(PulseColor.textPrimary)
        }
    }
}
