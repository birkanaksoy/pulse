import SwiftUI
import Observation

/// Central router for deep links coming from widgets, notifications, Siri, and
/// Spotlight. The UI watches the published intent and reacts accordingly.
@Observable
@MainActor
final class DeepLinkRouter {
    enum Intent: Equatable {
        case openHome
        case openHomeAndScan
        case openHealth
        case openClean
        case openSettings
        case openPaywall
    }

    /// Set by sources (URL handlers, notification delegate). UI clears after handling.
    var pendingIntent: Intent?

    func handle(url: URL) {
        // pulse://home, pulse://home/scan, pulse://health, etc.
        guard url.scheme == "pulse" else { return }
        let host = url.host ?? ""
        let path = url.path

        switch (host, path) {
        case ("home", "/scan"):   pendingIntent = .openHomeAndScan
        case ("home", _):         pendingIntent = .openHome
        case ("health", _):       pendingIntent = .openHealth
        case ("clean",  _):       pendingIntent = .openClean
        case ("settings", _):     pendingIntent = .openSettings
        case ("paywall", _):      pendingIntent = .openPaywall
        default:                  pendingIntent = .openHome
        }
    }

    func consume() -> Intent? {
        let intent = pendingIntent
        pendingIntent = nil
        return intent
    }
}
