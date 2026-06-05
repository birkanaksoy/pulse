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
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func tabButton(_ item: Item) -> some View {
        Button {
            if selection != item.id {
                Haptics.tap(0.35)
                if reduceMotion {
                    selection = item.id
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = item.id
                    }
                }
            }
        } label: {
            let active = selection == item.id
            ZStack {
                if active {
                    Capsule()
                        .fill(PulseColor.blue500.opacity(0.12))
                        .matchedGeometryEffect(id: "tab", in: ns)
                }
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolVariant(active ? .fill : .none)
                    if active {
                        Text(item.label)
                            .font(.system(size: 13, weight: .semibold))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundStyle(active ? PulseColor.blue500 : PulseColor.textTertiary)
                .padding(.horizontal, active ? 16 : 12)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.label))
        .accessibilityAddTraits(selection == item.id ? .isSelected : [])
    }
}
