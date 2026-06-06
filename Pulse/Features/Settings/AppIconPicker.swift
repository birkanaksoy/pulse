import SwiftUI
import UIKit

struct AppIconOption: Identifiable {
    var id: String { name ?? "default" }
    /// nil = primary icon
    var name: String?
    var displayName: LocalizedStringKey
    var previewAsset: String
}

@MainActor
enum AppIconManager {
    static let options: [AppIconOption] = [
        .init(name: nil,         displayName: "Mono",     previewAsset: "AppIcon-Default-Preview"),
        .init(name: "Midnight",  displayName: "Midnight", previewAsset: "AppIcon-Midnight@3x"),
        .init(name: "Health",    displayName: "Health",   previewAsset: "AppIcon-Health@3x"),
        .init(name: "Sunset",    displayName: "Sunset",   previewAsset: "AppIcon-Sunset@3x"),
    ]

    static var current: String? {
        UIApplication.shared.alternateIconName
    }

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
            VStack(alignment: .leading, spacing: PulseSpace.xxl) {
                header
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: PulseSpace.l),
                              GridItem(.flexible(), spacing: PulseSpace.l)],
                    spacing: PulseSpace.l
                ) {
                    ForEach(AppIconManager.options) { opt in
                        iconCell(opt)
                    }
                }
                Text("Alternate icons are a Pulse Pro perk.")
                    .font(PulseFont.footnote)
                    .foregroundStyle(PulseColor.textTertiary)
                    .padding(.horizontal, PulseSpace.s)
            }
            .padding(PulseSpace.xl)
            .padding(.bottom, PulseSpace.xxxl)
        }
        .background(AmbientBackground(tint: PulseColor.blue500))
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView().pulseSheet() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pick your look")
                .font(PulseFont.titleXL)
                .foregroundStyle(PulseColor.textPrimary)
            Text("Pro unlocks the three alternate icons. The change is instant.")
                .font(PulseFont.callout)
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
            VStack(spacing: PulseSpace.s) {
                ZStack(alignment: .topTrailing) {
                    iconPreview(opt)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(selected ? PulseColor.blue500 : PulseColor.stroke,
                                              lineWidth: selected ? 3 : 1)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 14, y: 6)

                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(PulseColor.blue500))
                            .offset(x: 8, y: -8)
                    } else if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(PulseColor.blue500))
                            .offset(x: 8, y: -8)
                    }
                }
                Text(opt.displayName)
                    .font(PulseFont.callout)
                    .foregroundStyle(PulseColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PulseSpace.m)
        }
        .buttonStyle(.card)
    }

    @ViewBuilder
    private func iconPreview(_ opt: AppIconOption) -> some View {
        if opt.name == nil {
            // Primary icon (Mono) — in-app preview that mirrors the rendered PNG
            ZStack {
                Color.white
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [Color.black, Color(white: 0.4)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        lineWidth: 12
                    )
                    .frame(width: 78, height: 78)
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.black, Color(white: 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 24, height: 24)
            }
        } else if let img = UIImage(named: opt.previewAsset) {
            Image(uiImage: img).resizable().aspectRatio(contentMode: .fit)
        } else {
            Color.gray.opacity(0.1)
        }
    }
}
