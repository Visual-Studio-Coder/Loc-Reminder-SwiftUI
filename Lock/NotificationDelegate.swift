/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
import Foundation
import UserNotifications
import SwiftUI

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    private var processedResponses: Set<String> = []
    
    private override init() {
        super.init()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Will present notification: \(notification.request.content.title)")
        
        // Keep the badge persistent
        let currentBadge = UIApplication.shared.applicationIconBadgeNumber
        UIApplication.shared.applicationIconBadgeNumber = max(1, currentBadge)
        
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📱 Did receive notification response: \(response.notification.request.content.title)")
        print("   Action identifier: \(response.actionIdentifier)")
        
        // Create unique response ID to prevent duplicates
        let responseId = "\(response.notification.request.identifier)-\(response.actionIdentifier)"
        
        // Check if we've already processed this response
        if processedResponses.contains(responseId) {
            print("🔄 Ignoring duplicate response: \(responseId)")
            completionHandler()
            return
        }
        
        // Mark as processed
        processedResponses.insert(responseId)
        
        // Clean up old processed responses (keep only last 50)
        if processedResponses.count > 50 {
            let sortedResponses = Array(processedResponses)
            processedResponses = Set(sortedResponses.suffix(25))
        }
        
        let userInfo = response.notification.request.content.userInfo
        let spotName = userInfo["spotName"] as? String ?? "Unknown Location"
        let spotId = userInfo["spotId"] as? String
        let isTestNotification = userInfo["isTestNotification"] as? Bool ?? false
        
        // Always clear the badge when user responds
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Handle different actions using the correct identifiers
        switch response.actionIdentifier {
        case "GOOD":
            print("✅ User responded: GOOD to \(spotName)")
            LogManager.shared.addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: "Good"
            )
            
        case "BAD":
            print("❌ User responded: BAD to \(spotName)")
            LogManager.shared.addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: "Not Good"
            )
            // Schedule a reminder for later
            scheduleReminderNotification(spotName: spotName, isTest: isTestNotification)
            
        case "EDIT", "EDIT_SPOT":
            print("✏️ User chose: EDIT for \(spotName)")
            LogManager.shared.addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: "Edit"
            )
            
            // Open the app to the spot editing view
            if let spotId = spotId, !isTestNotification {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenSpotForEditing"),
                        object: nil,
                        userInfo: ["spotId": spotId]
                    )
                }
            }
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped notification for \(spotName)")
            LogManager.shared.addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: "Tapped"
            )
            
        case UNNotificationDismissActionIdentifier:
            print("🚫 User dismissed notification for \(spotName)")
            LogManager.shared.addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: "Dismissed"
            )
            
        default:
            print("📱 Unknown action: \(response.actionIdentifier)")
            LogManager.shared.addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: response.actionIdentifier
            )
        }
        
        completionHandler()
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
