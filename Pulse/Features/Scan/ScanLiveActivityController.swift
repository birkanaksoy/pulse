import ActivityKit
import Foundation

@MainActor
enum ScanLiveActivityController {
    private static var current: Activity<ScanActivityAttributes>?

    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func start() {
        guard isAvailable, current == nil else { return }
        let state = ScanActivityAttributes.ContentState(
            progress: 0,
            phase: String(localized: "Reading sensors…"),
            finalScore: nil
        )
        do {
            current = try Activity.request(
                attributes: ScanActivityAttributes(),
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            current = nil
        }
    }

    static func update(progress: Double, phase: String) {
        Task {
            await current?.update(
                ActivityContent(
                    state: .init(progress: progress, phase: phase, finalScore: nil),
                    staleDate: nil
                )
            )
        }
    }

    static func end(score: Int) {
        Task {
            let finalState = ScanActivityAttributes.ContentState(
                progress: 1, phase: String(localized: "Complete"), finalScore: score
            )
            await current?.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(8))
            )
            current = nil
        }
    }
}
