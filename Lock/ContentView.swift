/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  ContentView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 4/25/23.
//

import SwiftUI
import CoreLocation
import UserNotifications
import CoreData

struct ContentView: View {
    // This AppStorage variable is the source of truth for whether onboarding has been completed.
    // `false` means onboarding should be shown.
    // `true` means onboarding has been completed and shouldn't be shown automatically.
    @AppStorage("shouldShowOnboarding") var shouldShowOnboarding: Bool = true

    // Local state to control the presentation of the fullScreenCover.
    @State private var showOnboardingCover: Bool = false

    // Create single instances here to be shared
    @StateObject private var locationManager = LocationDataManager()
    @StateObject private var dataController = DataController()
    @State private var selectedTab = 0 // Add tab selection state
    @State private var spotToEditFromNotification: String? // Track spot to edit from notification

    var body: some View {
        MainTabView(selectedTab: $selectedTab, spotToEditFromNotification: $spotToEditFromNotification)
            .environmentObject(locationManager)
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .fullScreenCover(isPresented: $shouldShowOnboarding) {
                // OnboardingView will also get the locationManager and moc from the environment
                OnboardingView(isPresented: $shouldShowOnboarding)
                    .environmentObject(locationManager)
                    .environment(\.managedObjectContext, dataController.container.viewContext)
            }
            .onAppear {
                // Set up notification delegate and categories
                setupNotifications()
                
                // Inject the managed object context into the location manager
                locationManager.setManagedObjectContext(dataController.container.viewContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSpotForEditing"))) { notification in
                if let spotId = notification.userInfo?["spotId"] as? String {
                    // Switch to spots tab and set spot to edit
                    selectedTab = 0 // Spots tab
                    spotToEditFromNotification = spotId
                }
            }
    }
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        
        // Define notification actions - using the actual identifiers your app sends
        let goodAction = UNNotificationAction(
            identifier: "GOOD",
            title: "👍 Good",
            options: [.foreground]
        )
        
        let badAction = UNNotificationAction(
            identifier: "BAD", 
            title: "👎 Not Good",
            options: [.foreground]
        )
        
        let editAction = UNNotificationAction(
            identifier: "EDIT",
            title: "✏️ Edit",
            options: [.foreground]
        )
        
        // Create the category with actions
        let locationCategory = UNNotificationCategory(
            identifier: "LOCATION_REMINDER",
            actions: [goodAction, badAction, editAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the category
        center.setNotificationCategories([locationCategory])
        
        print("✅ Notification categories registered with actions: GOOD, BAD, EDIT")
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var spotToEditFromNotification: String?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SpotBrowser(spotToEditFromNotification: $spotToEditFromNotification)
                .tabItem {
                    Label("Spots", systemImage: "mappin.and.ellipse")
                }
                .tag(0)
            
            SpotNotificationLogger() // Use your original SpotNotificationLogger view
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            InfoTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
