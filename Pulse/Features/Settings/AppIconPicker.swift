import SwiftUI
import UIKit

struct AppIconOption: Identifiable {
    var id: String { name ?? "default" }
    var name: String?              // nil = primary icon
    var displayName: LocalizedStringKey
    var previewAsset: String       // imageset name in Assets
}

@MainActor
enum AppIconManager {
    static let options: [AppIconOption] = [
        .init(name: nil,        displayName: "Swipe",     previewAsset: "BrandLogo"),
        .init(name: "TwoTone",  displayName: "Two-tone",  previewAsset: "AppIcon-TwoTone@3x"),
        .init(name: "Gauge",    displayName: "Gauge",     previewAsset: "AppIcon-Gauge@3x"),
        .init(name: "Sonar",    displayName: "Sonar",     previewAsset: "AppIcon-Sonar@3x"),
    ]

    static var current: String? { UIApplication.shared.alternateIconName }

    static func setIcon(_ name: String?) async throws {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard current != name else { return }
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

struct AppIconPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlements
    @State private var currentName: String? = AppIconManager.current
    @State private var showingPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12),
                              GridItem(.flexible(), spacing: 12)],
                    spacing: 14
                ) {
                    ForEach(AppIconManager.options) { opt in
                        iconCell(opt)
                    }
                }
                Text("Alternate icons are a Pulse Pro perk.")
                    .font(.system(size: 12))
                    .foregroundStyle(PulseColor.textTertiary)
                    .padding(.horizontal, 4)
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .sheet(isPresented: $showingPaywall) {
            SpecialOfferPaywallView(seenOffer: .constant(true))
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pick your look")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pro unlocks three alternates. Tap any to switch instantly.")
                .font(.system(size: 14))
                .foregroundStyle(PulseColor.textSecondary)
        }
    }

    @ViewBuilder
    private func iconCell(_ opt: AppIconOption) -> some View {
        let selected = currentName == opt.name
        let locked = opt.name != nil && !entitlements.isPro
        Button {
            Haptics.tap()
            if locked {
                showingPaywall = true
                return
            }
            Task {
                try? await AppIconManager.setIcon(opt.name)
                currentName = AppIconManager.current
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(opt.previewAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(selected ? PulseColor.blue500 : PulseColor.stroke,
                                              lineWidth: selected ? 3 : 1)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 14, y: 6)

                    if locked {
                        badge(systemImage: "lock.fill", color: PulseColor.blue500)
                    } else if selected {
                        badge(systemImage: "checkmark", color: PulseColor.blue500)
                    }
                }
                Text(opt.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PulseColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 20).fill(PulseColor.card))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(PulseColor.stroke))
        }
        .buttonStyle(.plain)
    }

    private func badge(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Circle().fill(color))
            .offset(x: 6, y: -6)
    }
}
