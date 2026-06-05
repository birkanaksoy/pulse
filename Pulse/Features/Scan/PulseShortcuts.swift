import AppIntents

/// Surfaces ScanIntent in the Shortcuts app and to Siri. Once installed, the
/// user can say "Run Pulse scan" or add the shortcut as a tile / lock-screen
/// action with no extra setup.
struct PulseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanIntent(),
            phrases: [
                "Run \(.applicationName) scan",
                "Scan with \(.applicationName)",
                "Check my \(.applicationName) score",
                "\(.applicationName) sağlık taraması",
                "\(.applicationName) skorumu kontrol et"
            ],
            shortTitle: "Run Scan",
            systemImageName: "waveform.path.ecg"
        )
    }

    /// Tile colour in the Shortcuts app.
    static var shortcutTileColor: ShortcutTileColor { .blue }
}
