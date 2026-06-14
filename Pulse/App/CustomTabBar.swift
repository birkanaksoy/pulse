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
        .frame(height: 58)
        .background(
            ZStack {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.overlay)
            }
        )
        .overlay(
            Capsule().strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.45), .white.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.6
            )
        )
        .shadow(color: .black.opacity(0.18), radius: 22, y: 12)
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
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
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
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .foregroundStyle(active ? Color.white : PulseColor.textTertiary)
            .padding(.horizontal, active ? 16 : 6)
            .frame(height: 42)
            .frame(minWidth: active ? nil : 46, maxWidth: active ? nil : .infinity)
            .background(
                ZStack {
                    if active {
                        Capsule(style: .continuous)
                            .fill(PulseColor.ringGradient)
                            .matchedGeometryEffect(id: "tabHighlight", in: ns)
                            .shadow(color: PulseColor.blue500.opacity(0.45), radius: 8, y: 4)
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
