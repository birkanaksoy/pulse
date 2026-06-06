import Foundation
import TelemetryDeck

/// TelemetryDeck-backed analytics. Anonymous by default — TelemetryDeck does
/// not collect IDFA or personal identifiers. Replace `appID` with your value
/// from https://dashboard.telemetrydeck.com/
@MainActor
enum TelemetryAnalyticsBootstrap {
    /// The TelemetryDeck app ID. Replace this with your real ID before launch.
    /// Keep it client-side; TelemetryDeck does not authenticate per-event.
    static let appID = "REPLACE_WITH_TELEMETRY_APP_ID"

    static func start() {
        guard appID != "REPLACE_WITH_TELEMETRY_APP_ID" else {
            // Don't initialize with the placeholder — silently use LocalAnalytics.
            return
        }
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
    }
}

struct TelemetryAnalytics: PulseAnalytics {
    func track(_ event: AnalyticsEvent) {
        TelemetryDeck.signal(event.name, parameters: event.payload)
    }
}
