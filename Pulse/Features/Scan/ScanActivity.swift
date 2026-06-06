import ActivityKit
import Foundation

/// Live Activity for an in-flight Pulse scan. Shows in the Dynamic Island and
/// the Lock Screen while a scan is running, then ends with the final score.
struct ScanActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double    // 0..1
        var phase: String       // "Scanning storage…" etc.
        var finalScore: Int?    // set when phase == .complete
    }
}
