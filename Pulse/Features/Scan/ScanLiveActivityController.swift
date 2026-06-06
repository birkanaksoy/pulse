import ActivityKit
import Foundation
import os.log

/// Owns the lifecycle of the Pulse scan Live Activity.
///
/// We don't auto-end on scan completion any more — the activity sticks around
/// for several hours (default Live Activity max ~8h) showing the final score on
/// the Lock Screen and in the Dynamic Island. When the silent BackgroundScanner
/// runs, it refreshes the live activity in place via `updateActiveActivities`.
///
/// To enable **server push** for Live Activities (iOS 17.2+):
/// 1. Add the Push Notifications capability to the Pulse target.
/// 2. Call `subscribeToPushUpdates(_:)` and forward the resulting push token to
///    your backend. The backend sends APNs payloads to `https://api.push.apple.com/3/device/<token>`
///    with `apns-push-type: liveactivity`.
/// 3. Replace the `.token` request below with `.token` and watch token updates
///    arrive via `pushTokenUpdates`.
@MainActor
enum ScanLiveActivityController {
    private static let log = Logger(subsystem: "app.pulse", category: "live-activity")

    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static var hasActive: Bool {
        !Activity<ScanActivityAttributes>.activities.isEmpty
    }

    // MARK: - Lifecycle

    static func start() {
        guard isAvailable, !hasActive else { return }
        let state = ScanActivityAttributes.ContentState(
            progress: 0,
            phase: String(localized: "Reading sensors…"),
            finalScore: nil
        )
        do {
            let activity = try Activity.request(
                attributes: ScanActivityAttributes(),
                content: .init(state: state, staleDate: nil),
                pushType: .token  // ready for server push wiring
            )
            log.info("Live Activity started: \(activity.id, privacy: .public)")
            Task { await observePushTokens(activity) }
        } catch {
            log.error("Failed to start: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func update(progress: Double, phase: String) {
        Task {
            for activity in Activity<ScanActivityAttributes>.activities {
                await activity.update(
                    ActivityContent(
                        state: .init(progress: progress, phase: phase, finalScore: nil),
                        staleDate: nil
                    )
                )
            }
        }
    }

    /// Final state — keep the activity alive for the iOS-max window so the
    /// Lock Screen / Dynamic Island keeps showing the score.
    static func end(score: Int) {
        Task {
            let finalState = ScanActivityAttributes.ContentState(
                progress: 1,
                phase: String(localized: "Complete"),
                finalScore: score
            )
            for activity in Activity<ScanActivityAttributes>.activities {
                await activity.update(
                    ActivityContent(state: finalState, staleDate: nil)
                )
            }
        }
    }

    /// Called when the user explicitly dismisses the activity from Settings →
    /// Pulse or from our own UI.
    static func dismissAll() {
        Task {
            for activity in Activity<ScanActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Updates any active activity with a freshly-computed score (called from
    /// `BackgroundScanner` after a silent weekly scan).
    static func refreshActiveWith(score: Int) {
        Task {
            let state = ScanActivityAttributes.ContentState(
                progress: 1,
                phase: String(localized: "Updated by background scan"),
                finalScore: score
            )
            for activity in Activity<ScanActivityAttributes>.activities {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
    }

    // MARK: - Push token observation

    /// Listens for ActivityKit push tokens and logs them. Wire this to your
    /// backend (POST to a `/registerLiveActivity` endpoint) to enable server
    /// push updates.
    private static func observePushTokens(_ activity: Activity<ScanActivityAttributes>) async {
        for await tokenData in activity.pushTokenUpdates {
            let hex = tokenData.map { String(format: "%02x", $0) }.joined()
            log.info("Live Activity push token: \(hex, privacy: .public)")
            // TODO: send hex token to your backend for server-driven updates.
        }
    }
}
