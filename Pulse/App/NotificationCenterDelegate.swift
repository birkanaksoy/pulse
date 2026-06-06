import UIKit
import UserNotifications

/// Routes notification taps into the deep-link router so the weekly reminder
/// can land on Home + auto-scan instead of just opening the app cold.
@MainActor
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    var router: DeepLinkRouter?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.identifier == NotificationScheduler.weeklyReminderID else {
            return
        }
        router?.pendingIntent = .openHomeAndScan
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
