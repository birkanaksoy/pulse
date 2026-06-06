import SwiftUI

struct CustomTabBar: View {
    @Binding var selection: RootView.Tab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var ns

    private struct Item: Identifiable {
        let id: RootView.Tab
        let icon: String
        let label: LocalizedStringKey
    }

    private let items: [Item] = [
        .init(id: .home,     icon: "waveform.path.ecg", label: "Home"),
        .init(id: .clean,    icon: "sparkles",          label: "Clean"),
        .init(id: .health,   icon: "chart.xyaxis.line", label: "Health"),
        .init(id: .settings, icon: "gearshape",         label: "Settings"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 56)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                )
        )
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func tabButton(_ item: Item) -> some View {
        let active = selection == item.id

        Button {
            guard selection != item.id else { return }
            Haptics.tap(0.35)
            if reduceMotion {
                selection = item.id
            } else {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    selection = item.id
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolVariant(active ? .fill : .none)
                if active {
                    Text(item.label)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .truncationMode(.tail)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .foregroundStyle(active ? PulseColor.blue500 : PulseColor.textTertiary)
            .padding(.horizontal, active ? 14 : 6)
            .frame(height: 40)
            .frame(minWidth: active ? nil : 44, maxWidth: active ? nil : .infinity)
            .background(
                ZStack {
                    if active {
                        Capsule(style: .continuous)
                            .fill(PulseColor.blue500.opacity(0.12))
                            .matchedGeometryEffect(id: "tabHighlight", in: ns)
                    }
                }
            )
            .contentShape(Capsule())
            .fixedSize(horizontal: active, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.label))
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
