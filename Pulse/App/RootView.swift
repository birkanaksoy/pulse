import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: Hashable { case home, clean, health, settings }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "waveform.path.ecg") }
                .tag(Tab.home)

            CleanView()
                .tabItem { Label("Clean", systemImage: "sparkles") }
                .tag(Tab.clean)

            HealthView()
                .tabItem { Label("Health", systemImage: "chart.xyaxis.line") }
                .tag(Tab.health)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}
