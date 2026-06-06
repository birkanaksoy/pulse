import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let unlocked: Bool
    let unlockedAt: Date?
    /// 0..1 progress towards unlock if locked.
    let progress: Double
}

enum AchievementsEngine {
    static func compute(records: [ScanRecord], streak: StreakState, isPro: Bool) -> [Achievement] {
        var out: [Achievement] = []
        let totalScans = records.count
        let bestScore  = records.map(\.pulseScore).max() ?? 0
        let firstAt    = records.last?.timestamp

        // First scan
        out.append(make(
            id: "first_scan",
            title: String(localized: "First scan"),
            detail: String(localized: "Take your phone's pulse for the first time."),
            icon: "waveform.path.ecg",
            unlocked: totalScans >= 1,
            unlockedAt: firstAt,
            progress: min(1.0, Double(totalScans))
        ))

        // 10 scans
        out.append(make(
            id: "ten_scans",
            title: String(localized: "Regular check-up"),
            detail: String(localized: "Run 10 scans."),
            icon: "checkmark.seal",
            unlocked: totalScans >= 10,
            unlockedAt: records.dropFirst(max(0, totalScans - 10)).first?.timestamp,
            progress: min(1.0, Double(totalScans) / 10.0)
        ))

        // 50 scans
        out.append(make(
            id: "fifty_scans",
            title: String(localized: "Dedicated"),
            detail: String(localized: "Run 50 scans."),
            icon: "rosette",
            unlocked: totalScans >= 50,
            unlockedAt: nil,
            progress: min(1.0, Double(totalScans) / 50.0)
        ))

        // Streak 3
        out.append(make(
            id: "streak_3",
            title: String(localized: "Three-day streak"),
            detail: String(localized: "Scan three days in a row."),
            icon: "flame",
            unlocked: streak.best >= 3,
            unlockedAt: nil,
            progress: min(1.0, Double(streak.best) / 3.0)
        ))

        // Streak 7
        out.append(make(
            id: "streak_7",
            title: String(localized: "Week-long streak"),
            detail: String(localized: "Scan seven days in a row."),
            icon: "flame.fill",
            unlocked: streak.best >= 7,
            unlockedAt: nil,
            progress: min(1.0, Double(streak.best) / 7.0)
        ))

        // Streak 30
        out.append(make(
            id: "streak_30",
            title: String(localized: "Month-long streak"),
            detail: String(localized: "Scan thirty days in a row."),
            icon: "calendar.badge.checkmark",
            unlocked: streak.best >= 30,
            unlockedAt: nil,
            progress: min(1.0, Double(streak.best) / 30.0)
        ))

        // High score 85+
        out.append(make(
            id: "score_85",
            title: String(localized: "Healthy phone"),
            detail: String(localized: "Reach an Excellent Pulse Score."),
            icon: "checkmark.circle.fill",
            unlocked: bestScore >= 85,
            unlockedAt: nil,
            progress: min(1.0, Double(bestScore) / 85.0)
        ))

        // High score 100
        out.append(make(
            id: "score_100",
            title: String(localized: "Perfect Pulse"),
            detail: String(localized: "Reach a Pulse Score of 100."),
            icon: "star.fill",
            unlocked: bestScore >= 100,
            unlockedAt: nil,
            progress: min(1.0, Double(bestScore) / 100.0)
        ))

        // Pro supporter
        out.append(make(
            id: "pro_supporter",
            title: String(localized: "Supporter"),
            detail: String(localized: "Unlock Pulse Pro and back the app."),
            icon: "heart.fill",
            unlocked: isPro,
            unlockedAt: nil,
            progress: isPro ? 1.0 : 0.0
        ))

        return out
    }

    private static func make(id: String, title: String, detail: String, icon: String,
                             unlocked: Bool, unlockedAt: Date?, progress: Double) -> Achievement {
        Achievement(id: id, title: title, detail: detail, icon: icon,
                    unlocked: unlocked, unlockedAt: unlockedAt, progress: progress)
    }
}
