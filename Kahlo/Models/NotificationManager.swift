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
    
    // MARK: - Background Running Notification

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

    // MARK: - Trade Execution Notifications

    /// Send an alert when a BUY trade fires in the background.
    public func sendTradeNotification(side: String, symbol: String, price: Double, amount: Double) {
        let content = UNMutableNotificationContent()
        let emoji = side == "BUY" ? "🟢" : "🔴"
        content.title = "\(emoji) Kahlo: \(side) \(symbol)"
        content.body = String(
            format: "%@ %.6f %@ @ $%.2f",
            side == "BUY" ? "Bought" : "Sold",
            amount,
            symbol,
            price
        )
        content.sound = .default
        // Show the current price as the subtitle
        content.subtitle = String(format: "Price: $%.2f", price)

        let identifier = "KahloTrade-\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error posting trade notification: \(error.localizedDescription)")
            }
        }
    }

    /// Send an alert for stop-loss or take-profit events.
    public func sendRiskNotification(event: String, symbol: String, price: Double, pnl: Double) {
        let content = UNMutableNotificationContent()
        let emoji = event == "stop-loss" ? "⛔️" : "✅"
        let eventTitle = event == "stop-loss" ? "Stop-Loss Hit" : "Take-Profit Hit"
        content.title = "\(emoji) Kahlo: \(eventTitle)"
        content.body = String(
            format: "%@ triggered for %@ @ $%.2f | PnL: %+.2f%%",
            eventTitle,
            symbol,
            price,
            pnl
        )
        content.sound = .defaultCritical

        let identifier = "KahloRisk-\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error posting risk notification: \(error.localizedDescription)")
            }
        }
    }

    /// Send custom price alert notification.
    public func sendPriceAlertNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let identifier = "KahloAlert-\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error posting alert notification: \(error.localizedDescription)")
            }
        }
    }
}
