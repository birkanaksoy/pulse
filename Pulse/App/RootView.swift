import SwiftUI

struct RootView: View {
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            SweepView()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        Haptics.tap(0.25)
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(PulseColor.textPrimary)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                            .overlay(Circle().strokeBorder(PulseColor.stroke, lineWidth: 0.5))
                    }
                    .accessibilityLabel(Text("Settings"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                Spacer()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDragIndicator(.visible)
        }
    }
}
