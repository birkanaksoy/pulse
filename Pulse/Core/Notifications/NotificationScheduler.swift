import Foundation
import UserNotifications

enum NotificationScheduler {
    static let weeklyReminderID = "pulse.weekly.reminder"

    /// Asks for notification permission. Returns true if granted.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func currentStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Schedules a weekly Sunday 10:00 AM reminder. Idempotent — safe to call repeatedly.
    static func scheduleWeeklyReminder() {
        cancelWeeklyReminder()

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Pulse check-in")
        content.body  = String(localized: "It's been a week. Run a scan to see how your phone's doing.")
        content.sound = .default

        var date = DateComponents()
        date.weekday = 1   // Sunday
        date.hour    = 10
        date.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: weeklyReminderID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelWeeklyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [weeklyReminderID])
    }
}
