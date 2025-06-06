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
    @AppStorage("shouldShowOnboarding") var dontShowOnboarding: Bool = false
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
                        dontShowOnboarding = false
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
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Test Location Reminder"
        content.body = "This is a test notification with all available actions"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "LOCATION_REMINDER"
        content.userInfo = ["spotName": "Test Location", "spotId": "test-spot-id", "isEntry": true]
        
        // Increment badge for test notification
        UIApplication.shared.applicationIconBadgeNumber += 1
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber)
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Test notification error: \(error)")
            } else {
                print("✅ Test notification sent")
                LogManager.shared.addLog(
                    eventType: .notificationSent,
                    spotName: "Test Location",
                    message: "Test notification sent from About tab"
                )
            }
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
