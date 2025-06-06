/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
import Foundation
import UserNotifications
import SwiftUI

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("📱 Notification action received: \(response.actionIdentifier)")
        
        let spotName = response.notification.request.content.userInfo["spotName"] as? String ?? "Unknown Location"
        let spotId = response.notification.request.content.userInfo["spotId"] as? String
        
        // Decrease badge count for user responses (not default tap)
        if response.actionIdentifier != UNNotificationDefaultActionIdentifier {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = max(0, currentBadge - 1)
        }
        
        switch response.actionIdentifier {
        case "OKAY":
            print("✅ User responded: Okay")
            NotificationCenter.default.post(
                name: NSNotification.Name("NotificationResponse"),
                object: nil,
                userInfo: ["response": "Okay", "spotName": spotName]
            )
            break
        case "NOT_OKAY":
            print("❌ User responded: Not Okay")
            NotificationCenter.default.post(
                name: NSNotification.Name("NotificationResponse"),
                object: nil,
                userInfo: ["response": "Not Okay", "spotName": spotName]
            )
            break
        case "EDIT_SPOT":
            print("📝 User wants to edit spot")
            NotificationCenter.default.post(
                name: NSNotification.Name("NotificationResponse"),
                object: nil,
                userInfo: ["response": "Edit Spot", "spotName": spotName]
            )
            if let spotId = spotId {
                NotificationCenter.default.post(
                    name: NSNotification.Name("EditSpotFromNotification"),
                    object: spotId
                )
            }
            break
        default:
            print("📱 Default notification tap")
            NotificationCenter.default.post(
                name: NSNotification.Name("NotificationResponse"),
                object: nil,
                userInfo: ["response": "Tapped", "spotName": spotName]
            )
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
}
