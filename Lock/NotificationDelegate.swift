/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
import Foundation
import UserNotifications
import SwiftUI

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📱 Did receive notification response: \(response.notification.request.content.title)")
        print("   Action identifier: \(response.actionIdentifier)")
        
        let userInfo = response.notification.request.content.userInfo
        let spotName = userInfo["spotName"] as? String ?? "Unknown Location"
        let spotId = userInfo["spotId"] as? String
        let isTestNotification = userInfo["isTestNotification"] as? Bool ?? false
        
        // Handle different actions using the correct identifiers
        switch response.actionIdentifier {
        case "GOOD":
            print("✅ User responded: GOOD to \(spotName)")
            if let logManager = LogManager.shared as? LogManager {
                logManager.addLog(
                    eventType: .userResponse,
                    spotName: spotName,
                    message: "Good"
                )
            }
            
        case "BAD":
            print("❌ User responded: BAD to \(spotName)")
            if let logManager = LogManager.shared as? LogManager {
                logManager.addLog(
                    eventType: .userResponse,
                    spotName: spotName,
                    message: "Not Good"
                )
            }
            // Schedule a reminder for later
            scheduleReminderNotification(spotName: spotName, isTest: isTestNotification)
            
        case "EDIT", "EDIT_SPOT": // Handle both possible identifiers
            print("✏️ User chose: EDIT for \(spotName)")
            if let logManager = LogManager.shared as? LogManager {
                logManager.addLog(
                    eventType: .userResponse,
                    spotName: spotName,
                    message: "Edit"
                )
            }
            
            // Open the app to the spot editing view
            if let spotId = spotId, !isTestNotification {
                DispatchQueue.main.async {
                    // Post a notification to open the specific spot for editing
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenSpotForEditing"),
                        object: nil,
                        userInfo: ["spotId": spotId]
                    )
                }
            } else if isTestNotification {
                // For test notifications, just open the app to spots tab
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenSpotForEditing"),
                        object: nil,
                        userInfo: ["spotId": "test"] // This will be ignored but triggers tab switch
                    )
                }
            }
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped notification for \(spotName)")
            if let logManager = LogManager.shared as? LogManager {
                logManager.addLog(
                    eventType: .userResponse,
                    spotName: spotName,
                    message: "Tapped"
                )
            }
            
        case UNNotificationDismissActionIdentifier:
            print("🚫 User dismissed notification for \(spotName)")
            if let logManager = LogManager.shared as? LogManager {
                logManager.addLog(
                    eventType: .userResponse,
                    spotName: spotName,
                    message: "Dismissed"
                )
            }
            
        default:
            print("📱 Unknown action: \(response.actionIdentifier)")
            if let logManager = LogManager.shared as? LogManager {
                logManager.addLog(
                    eventType: .userResponse,
                    spotName: spotName,
                    message: response.actionIdentifier
                )
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Will present notification: \(notification.request.content.title)")
        
        // Show the notification with banner, sound, and badge
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    private func scheduleReminderNotification(spotName: String, isTest: Bool) {
        let content = UNMutableNotificationContent()
        content.title = isTest ? "🧪 Test Reminder" : "📍 Location Reminder"
        content.body = "Don't forget about \(spotName)!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "LOCATION_REMINDER"
        content.userInfo = [
            "spotName": spotName,
            "isReminder": true,
            "isTestNotification": isTest
        ]
        
        // Schedule for 10 seconds later for testing (normally would be 10 minutes)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: isTest ? 10 : 600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder-\(spotName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling reminder: \(error)")
            } else {
                print("✅ Reminder scheduled for \(spotName) in \(isTest ? "10 seconds" : "10 minutes")")
            }
        }
    }
}
