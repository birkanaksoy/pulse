import Foundation
import os.log

/// Tiny, privacy-respecting analytics surface. Default implementation logs to
/// `os_log` only — nothing leaves the device. To wire TelemetryDeck (recommended
/// — anonymous, GDPR-friendly, free tier):
///
/// 1. File → Add Package Dependencies → https://github.com/TelemetryDeck/SwiftSDK
/// 2. Replace `LocalAnalytics` instance below with a `TelemetryAnalytics`
///    wrapper that calls `TelemetryDeck.signal(_:with:)`.
/// 3. Add `TelemetryAppID` to Info.plist with your app ID.
///
/// Keep events anonymous: no identifiers, no PII, no scan content — only event
/// names and coarse buckets.
protocol PulseAnalytics: Sendable {
    func track(_ event: AnalyticsEvent)
}

enum AnalyticsEvent {
    case appLaunched
    case onboardingCompleted
    case scanCompleted(scoreBucket: ScoreBucket)
    case scanFailed
    case paywallShown(trigger: String)
    case purchaseStarted(plan: String)
    case purchaseCompleted(plan: String)
    case purchaseRestored
    case widgetAdded
    case shareCardExported
    case ratingPromptShown

    enum ScoreBucket: String { case excellent, good, fair, critical }

    var name: String {
        switch self {
        case .appLaunched:          return "app_launched"
        case .onboardingCompleted:  return "onboarding_completed"
        case .scanCompleted:        return "scan_completed"
        case .scanFailed:           return "scan_failed"
        case .paywallShown:         return "paywall_shown"
        case .purchaseStarted:      return "purchase_started"
        case .purchaseCompleted:    return "purchase_completed"
        case .purchaseRestored:     return "purchase_restored"
        case .widgetAdded:          return "widget_added"
        case .shareCardExported:    return "share_card_exported"
        case .ratingPromptShown:    return "rating_prompt_shown"
        }
    }

    var payload: [String: String] {
        switch self {
        case .scanCompleted(let b):     return ["bucket": b.rawValue]
        case .paywallShown(let t):      return ["trigger": t]
        case .purchaseStarted(let p):   return ["plan": p]
        case .purchaseCompleted(let p): return ["plan": p]
        default:                        return [:]
        }
    }
}

struct LocalAnalytics: PulseAnalytics {
    private static let log = Logger(subsystem: "app.pulse", category: "analytics")
    func track(_ event: AnalyticsEvent) {
        let payloadString = event.payload.map { "\($0)=\($1)" }.joined(separator: " ")
        Self.log.info("\(event.name, privacy: .public) \(payloadString, privacy: .public)")
    }
}

@MainActor
enum Analytics {
    /// Picks TelemetryAnalytics when the TelemetryDeck app ID is configured,
    /// otherwise falls back to LocalAnalytics (os_log only — nothing leaves
    /// the device). Set the app ID in `TelemetryAnalyticsBootstrap.appID`.
    static let provider: any PulseAnalytics = {
        if TelemetryAnalyticsBootstrap.appID != "REPLACE_WITH_TELEMETRY_APP_ID" {
            return TelemetryAnalytics()
        }
        return LocalAnalytics()
    }()

    static func track(_ event: AnalyticsEvent) { provider.track(event) }
}
