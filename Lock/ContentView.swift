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

struct ContentView: View {
    // This AppStorage variable is the source of truth for whether onboarding has been completed.
    // `false` means onboarding should be shown.
    // `true` means onboarding has been completed and shouldn't be shown automatically.
    @AppStorage("shouldShowOnboarding") var dontShowOnboarding: Bool = false

    // Local state to control the presentation of the fullScreenCover.
    @State private var showOnboardingCover: Bool = false

    @Environment(\.managedObjectContext) var moc

    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spots>
    
    // Add location manager for monitoring
    @StateObject private var locationManager = LocationDataManager()

    var body: some View {
        TabView {
            SpotNotificationLogger()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Logs")
                }
            SpotBrowser()
                .tabItem {
                    Image(systemName: "mappin.circle.fill")
                    Text("Spots")
                }
            
            InfoTab()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
        }
        .onAppear {
            // Set up location manager with Core Data context
            locationManager.setManagedObjectContext(moc)
            
            // Request notification permissions explicitly and set up notification categories
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("✅ Notification permission granted in ContentView")
                    // Set up notification delegate to handle actions
                    DispatchQueue.main.async {
                        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                        self.setupNotificationCategories()
                    }
                } else {
                    print("❌ Notification permission denied in ContentView")
                }
            }
            
            // Start monitoring existing spots
            startMonitoringExistingSpots()
            
            // Debug: Print current authorization status
            print("Current location authorization: \(locationManager.locationManager.authorizationStatus)")
            print("Number of spots to monitor: \(spots.count)")
            
            // This will run when ContentView first appears.
            // We only want to trigger the onboarding if it hasn't been shown yet.
            if !dontShowOnboarding {
                // If onboarding has not been completed (dontShowOnboarding is false),
                // then set our state to show the cover.
                self.showOnboardingCover = true
            }
        }
        .onChange(of: dontShowOnboarding) { newValue in
            // This will run whenever dontShowOnboarding changes value.
            // For example, when OnboardingView sets it to true, or InfoTab sets it to false.
            // We update showOnboardingCover to reflect the desired state:
            // - If dontShowOnboarding becomes false (show it), showOnboardingCover becomes true.
            // - If dontShowOnboarding becomes true (hide it), showOnboardingCover becomes false.
            self.showOnboardingCover = !newValue
        }
        .fullScreenCover(isPresented: $showOnboardingCover) {
            OnboardingView()
            // OnboardingView will set `dontShowOnboarding = true` when it's dismissed by the user.
            // The .onChange modifier above will then set `showOnboardingCover = false`, dismissing this cover.
        }
    }
    
    // Method to start monitoring all existing spots
    private func startMonitoringExistingSpots() {
        print("🏁 Starting to monitor \(spots.count) existing spots")
        
        for spot in spots {
            print("🔍 Debugging spot: \(spot.nameOfLocation ?? "Unknown")")
            print("   ID: \(spot.id?.uuidString ?? "No ID")")
            print("   Latitude raw: \(spot.latitude)")
            print("   Longitude raw: \(spot.longitude)")
            print("   Address: \(spot.address ?? "No address")")
            print("   Distance: \(spot.distanceFromSpot)")
            
            if let id = spot.id {
                let coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
                print("   Coordinate created: \(coordinate.latitude), \(coordinate.longitude)")
                
                if coordinate.latitude != 0.0 && coordinate.longitude != 0.0 {
                    print("✅ Valid coordinates - Setting up monitoring for: \(spot.nameOfLocation ?? "Unknown")")
                    print("   Location: \(coordinate.latitude), \(coordinate.longitude)")
                    print("   Radius: \(spot.distanceFromSpot) meters")
                    
                    locationManager.monitorRegionAtLocation(center: coordinate, identifier: id.uuidString)
                } else {
                    print("❌ Invalid coordinates for spot: \(spot.nameOfLocation ?? "Unknown")")
                    print("   Latitude: \(coordinate.latitude)")
                    print("   Longitude: \(coordinate.longitude)")
                }
            } else {
                print("❌ No ID for spot: \(spot.nameOfLocation ?? "Unknown")")
            }
        }
        
        // Add a small delay then check what regions are being monitored
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("📊 Final monitoring status:")
            print("   Total regions being monitored: \(self.locationManager.locationManager.monitoredRegions.count)")
            for region in self.locationManager.locationManager.monitoredRegions {
                if let circularRegion = region as? CLCircularRegion {
                    print("   - \(region.identifier): radius \(circularRegion.radius)m")
                }
            }
        }
    }
    
    private func setupNotificationCategories() {
        let okayAction = UNNotificationAction(
            identifier: "OKAY",
            title: "Okay",
            options: []
        )
        
        let notOkayAction = UNNotificationAction(
            identifier: "NOT_OKAY",
            title: "Not Okay",
            options: [.foreground]
        )
        
        let editAction = UNNotificationAction(
            identifier: "EDIT_SPOT",
            title: "Edit Spot",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "LOCATION_REMINDER",
            actions: [okayAction, notOkayAction, editAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("✅ Notification categories set up in ContentView")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
     



extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
