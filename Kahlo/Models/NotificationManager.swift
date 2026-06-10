import Foundation
import UserNotifications

public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization failed: \(error.localizedDescription)")
            } else if granted {
                print("Notification authorization granted.")
            } else {
                print("Notification authorization denied.")
            }
        }
    }
    
    public func sendAlgoRunningInBackgroundNotification(symbol: String) {
        let content = UNMutableNotificationContent()
        content.title = "Kahlo Algo Running"
        content.body = "The trading algorithm for \(symbol) is active and running in the background."
        content.sound = .default
        
        // Deliver the notification in 1 second
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "KahloAlgoRunningNotification",
            content: content,
            trigger: trigger
        )
        
        // Remove pending/delivered ones first to avoid duplication
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["KahloAlgoRunningNotification"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["KahloAlgoRunningNotification"])
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error posting notification: \(error.localizedDescription)")
            }
        }
    }
}
