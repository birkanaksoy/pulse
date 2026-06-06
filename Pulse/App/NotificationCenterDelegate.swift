import UIKit
import UserNotifications

/// Routes notification taps into the deep-link router so a tap on a smart
/// alert or the weekly reminder lands at the right place — not just on Home.
@MainActor
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    var router: DeepLinkRouter?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let request = response.notification.request
        // Smart alerts ship a deep-link in userInfo.
        if let s = request.content.userInfo["deepLink"] as? String,
           let url = URL(string: s) {
            router?.handle(url: url)
            return
        }
        // Legacy: the weekly reminder identifier always means "scan now".
        if request.identifier == NotificationScheduler.weeklyReminderID {
            router?.pendingIntent = .openHomeAndScan
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
