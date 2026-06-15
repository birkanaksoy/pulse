import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .home
    @State private var engine = ScanEngine()
    @State private var cleanScanner = CleanScanner()
    @Environment(DeepLinkRouter.self) private var router
    @Environment(\.modelContext) private var context

    enum Tab: Hashable { case home, health, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home:     HomeView(engine: engine, scanner: cleanScanner)
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
        .onChange(of: router.pendingIntent) { _, intent in
            handle(intent: intent)
        }
        .onAppear {
            handle(intent: router.consume())
        }
    }

    private func handle(intent: DeepLinkRouter.Intent?) {
        guard let intent else { return }
        switch intent {
        case .openHome:
            selection = .home
        case .openHomeAndScan:
            selection = .home
            Task {
                await engine.runFullScan()
                if let r = engine.lastResult {
                    context.insert(ScanRecord.from(r))
                    try? context.save()
                    SharedScoreStore.save(.init(
                        score: r.pulseScore,
                        status: PulseStatus(score: r.pulseScore).label,
                        timestamp: r.timestamp,
                        isPro: false
                    ))
                }
            }
        case .openHealth:   selection = .health
        case .openClean:    selection = .home  // Clean is now a sheet on Home
        case .openSettings: selection = .settings
        case .openPaywall:
            selection = .settings
        }
        router.pendingIntent = nil
    }
}
