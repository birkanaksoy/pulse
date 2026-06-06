import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .home
    /// Owned at root so state survives tab switches.
    @State private var engine = ScanEngine()
    @State private var cleanScanner = CleanScanner()

    enum Tab: Hashable { case home, clean, health, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home:     HomeView(engine: engine)
                case .clean:    CleanView(scanner: cleanScanner)
                case .health:   HealthView()
                case .settings: SettingsView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 76)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.18), value: selection)

            CustomTabBar(selection: $selection)
        }
        .ignoresSafeArea(.keyboard)
    }
}
