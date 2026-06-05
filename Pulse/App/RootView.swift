import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: Hashable { case home, clean, health, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                HomeView().tag(Tab.home)
                CleanView().tag(Tab.clean)
                HealthView().tag(Tab.health)
                SettingsView().tag(Tab.settings)
            }
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 76) // reserve room for floating bar
            }

            CustomTabBar(selection: $selection)
        }
        .ignoresSafeArea(.keyboard)
    }
}
