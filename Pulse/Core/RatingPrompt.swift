import StoreKit
import SwiftUI

/// Asks Apple to show the in-app rating prompt at the right moment.
/// Strategy: at least 3 successful scans, latest score ≥ 70, ≥ 48h since install
/// or last prompt, never more than 3 prompts/year (Apple's hard cap).
@MainActor
enum RatingPrompt {
    private static let lastShownKey  = "pulse.rating.lastShown"
    private static let firstSeenKey  = "pulse.rating.firstSeen"
    private static let scansSeenKey  = "pulse.rating.scansSeen"

    static func recordScan() {
        let d = UserDefaults.standard
        if d.object(forKey: firstSeenKey) == nil {
            d.set(Date().timeIntervalSince1970, forKey: firstSeenKey)
        }
        d.set(d.integer(forKey: scansSeenKey) + 1, forKey: scansSeenKey)
    }

    static func maybeAsk(currentScore: Int, in scene: UIWindowScene?) {
        let d = UserDefaults.standard
        let scans = d.integer(forKey: scansSeenKey)
        guard scans >= 3 else { return }
        guard currentScore >= 70 else { return }

        let now = Date().timeIntervalSince1970
        let firstSeen = d.double(forKey: firstSeenKey)
        guard firstSeen > 0, now - firstSeen >= 48 * 3600 else { return }

        let lastShown = d.double(forKey: lastShownKey)
        if lastShown > 0, now - lastShown < 90 * 24 * 3600 { return }

        guard let scene else { return }
        SKStoreReviewController.requestReview(in: scene)
        d.set(now, forKey: lastShownKey)
        Analytics.track(.ratingPromptShown)
    }
}
