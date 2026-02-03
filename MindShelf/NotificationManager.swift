import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                    // Intentionally ignore result here; app can still schedule if already authorized.
                }
            }
        }
    }
    
    func scheduleReminder(bookmarkID: UUID, title: String, date: Date, url: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Hey, you wanted to check this out!"
        content.sound = .default
        content.userInfo = [
            "bookmarkID": bookmarkID.uuidString,
            "url": url
        ]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if let idString = info["bookmarkID"] as? String {
            NotificationCenter.default.post(name: .openBookmarkFromNotification, object: nil, userInfo: [
                "bookmarkID": idString,
                "url": info["url"] as? String ?? ""
            ])
        } else if let urlString = info["url"] as? String {
            NotificationCenter.default.post(name: .openBookmarkFromNotification, object: nil, userInfo: [
                "url": urlString
            ])
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let openBookmarkFromNotification = Notification.Name("openBookmarkFromNotification")
}
