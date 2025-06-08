/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  InfoTab.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/10/23.
//

import SwiftUI
import UserNotifications

struct InfoTab: View {
    @Environment(\.openURL) var openURL
    @AppStorage("shouldShowOnboarding") var shouldShowOnboarding: Bool = true
    @State private var showingAppInfo = false

    var body: some View {
        NavigationView {
            List {
                // Developer Section
                Section {
                    HStack {
                        AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/78756662?v=4")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Developer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Vaibhav Satishkumar")
                                .font(.headline)
                            Text("@Visual-Studio-Coder")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        openURL(URL(string: "https://github.com/Visual-Studio-Coder")!)
                    }
                }
                
                // Quick Actions Section
                Section("Quick Actions") {
                    Button {
                        shouldShowOnboarding = true
                    } label: {
                        Label("Show Onboarding Again", systemImage: "questionmark.circle")
                    }
                    
                    Button {
                        sendTestNotification()
                    } label: {
                        Label("Test Notification", systemImage: "bell.badge")
                    }
                    
                    Button {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsUrl)
                        }
                    } label: {
                        Label("Open App Settings", systemImage: "gear")
                    }
                }
                
                // Support Section
                Section("Support & Feedback") {
                    Button {
                        openURL(URL(string: "https://github.com/Visual-Studio-Coder/Loc-Reminder-SwiftUI/issues/new?template=bug_report.md")!)
                    } label: {
                        Label("Report Bug", systemImage: "ladybug.fill")
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        openURL(URL(string: "https://github.com/Visual-Studio-Coder/Loc-Reminder-SwiftUI/issues/new?template=feature_request.md")!)
                    } label: {
                        Label("Request Feature", systemImage: "lightbulb")
                            .foregroundColor(.orange)
                    }
                    
                    Button {
                        openURL(URL(string: "https://github.com/Visual-Studio-Coder/Loc-Reminder-SwiftUI/issues/new?template=BLANK_ISSUE")!)
                    } label: {
                        Label("General Feedback", systemImage: "bubble.left.and.bubble.right")
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                        openURL(URL(string: "itms-apps://itunes.apple.com/app/id1605302677?action=write-review")!)
                    } label: {
                        Label("Rate on App Store", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // Project Links Section
                Section("Project") {
                    Button {
                        openURL(URL(string: "https://github.com/Visual-Studio-Coder/Loc-Reminder-SwiftUI")!)
                    } label: {
                        Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Button {
                        openURL(URL(string: "https://github.com/Visual-Studio-Coder/Loc-Reminder-SwiftUI/blob/master/PRIVACY.md")!)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Button {
                        showingAppInfo = true
                    } label: {
                        Label("App Information", systemImage: "info.circle")
                    }
                }
                
                // Support the Developer Section
                Section("Support the Developer") {
                    Button {
                        openURL(URL(string: "https://buymeacoffee.com/visualstudiocoder")!)
                    } label: {
                        HStack {
                            Image("buycoffee")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            Text("Buy Me a Coffee")
                            Spacer()
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                        }
                    }
                }
                
                // Debug Section
                Section("Debug Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("App Version:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                                .font(.caption.monospaced())
                        }
                        
                        HStack {
                            Text("Build Number:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                                .font(.caption.monospaced())
                        }
                        
                        Button("Check Notification Status") {
                            checkNotificationStatus()
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("About")
            .sheet(isPresented: $showingAppInfo) {
                AppInfoView()
            }
        }
    }
    
    private func sendTestNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Notification Settings:")
                print("   Authorization Status: \(settings.authorizationStatus.rawValue)")
                print("   Alert Setting: \(settings.alertSetting.rawValue)")
                print("   Badge Setting: \(settings.badgeSetting.rawValue)")
                print("   Sound Setting: \(settings.soundSetting.rawValue)")
                print("   Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
                print("   Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
                
                guard settings.authorizationStatus == .authorized else {
                    print("❌ Notifications not authorized - status: \(settings.authorizationStatus.rawValue)")
                    return
                }
                
                self.createAndSendTestNotification()
            }
        }
    }
    
    private func createAndSendTestNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Set delegate to show notifications even when app is in foreground
        center.delegate = NotificationDelegate.shared
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Location Reminder"
        content.body = "Did you remember to lock your house? Tap to respond."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "LOCATION_REMINDER"
        content.userInfo = [
            "spotName": "Test Location", 
            "spotId": "test-spot-id", 
            "isEntry": true,
            "isTestNotification": true
        ]
        
        // Set badge to a persistent number and don't let it auto-clear
        content.badge = NSNumber(value: 1)
        
        // Use immediate trigger for testing
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Test notification error: \(error.localizedDescription)")
                } else {
                    print("✅ Test notification queued successfully")
                    
                    // Set the badge explicitly and keep it persistent
                    UIApplication.shared.applicationIconBadgeNumber = 1
                    
                    LogManager.shared.addLog(
                        eventType: .notificationSent,
                        spotName: "Test Location",
                        message: "Interactive test notification sent with Good/Not Good/Edit actions"
                    )
                }
            }
        }
        
        // Check registered categories
        center.getNotificationCategories { categories in
            DispatchQueue.main.async {
                print("📋 Registered categories: \(categories.count)")
                for category in categories {
                    print("   - \(category.identifier): \(category.actions.count) actions")
                    for action in category.actions {
                        print("     • \(action.identifier): \(action.title)")
                    }
                }
            }
        }
    }
    
    private func showTestAlert() {
        let alert = UIAlertController(
            title: "🧪 Interactive Test Notification Sent",
            message: "The test notification should appear with action buttons like your real location reminders. If you don't see it:\n\n• Put the app in background\n• Check notification settings\n• Look for the red badge on the app icon\n• Try tapping the notification to see the response options",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("\n📱 NOTIFICATION STATUS DEBUG:")
                print("Authorization: \(settings.authorizationStatus.rawValue) (\(self.authStatusString(settings.authorizationStatus)))")
                print("Alert: \(settings.alertSetting.rawValue) (\(self.settingString(settings.alertSetting)))")
                print("Badge: \(settings.badgeSetting.rawValue) (\(self.settingString(settings.badgeSetting)))")
                print("Sound: \(settings.soundSetting.rawValue) (\(self.settingString(settings.soundSetting)))")
                print("Notification Center: \(settings.notificationCenterSetting.rawValue) (\(self.settingString(settings.notificationCenterSetting)))")
                print("Lock Screen: \(settings.lockScreenSetting.rawValue) (\(self.settingString(settings.lockScreenSetting)))")
                if #available(iOS 15.0, *) {
                    print("Time Sensitive: \(settings.timeSensitiveSetting.rawValue) (\(self.settingString(settings.timeSensitiveSetting)))")
                }
                print("Current Badge: \(UIApplication.shared.applicationIconBadgeNumber)")
            }
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                print("Pending Notifications: \(requests.count)")
            }
        }
    }
    
    private func authStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func settingString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }
}

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Application Details") {
                    InfoRow(title: "Name", value: Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Loc Reminder")
                    InfoRow(title: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    InfoRow(title: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                    InfoRow(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
                }
                
                Section("Device Information") {
                    InfoRow(title: "iOS Version", value: UIDevice.current.systemVersion)
                    InfoRow(title: "Device Model", value: UIDevice.current.model)
                    InfoRow(title: "Device Name", value: UIDevice.current.name)
                }
                
                Section("Features") {
                    FeatureRow(title: "Location Services", description: "Track your location for geofencing", icon: "location.fill", color: .blue)
                    FeatureRow(title: "Notifications", description: "Receive alerts when entering/leaving spots", icon: "bell.fill", color: .orange)
                    FeatureRow(title: "Core Data", description: "Persistent storage for your spots", icon: "cylinder.fill", color: .green)
                    FeatureRow(title: "Background Monitoring", description: "Works even when app is closed", icon: "moon.fill", color: .purple)
                }
            }
            .navigationTitle("App Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.caption.monospaced())
        }
    }
}

struct FeatureRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoTab_Previews: PreviewProvider {
    static var previews: some View {
        InfoTab()
    }
}
