/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
import UIKit
import CoreLocation
import WidgetKit
import UserNotifications
import SwiftUI
import CoreData

@MainActor
class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var managedObjectContext: NSManagedObjectContext?
    private var activeNotifications: [String: String] = [:] // spotId -> notificationId mapping

    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Request notification permissions immediately
        requestNotificationPermission()
        
        // Debug: Print current monitoring capabilities
        print("Region monitoring available: \(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self))")
        print("Max monitored regions: \(CLLocationManager().maximumRegionMonitoringDistance)")
        print("Currently monitored regions: \(locationManager.monitoredRegions.count)")
    }
    
    func setManagedObjectContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                    self.setupNotificationCategories()
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("❌ Notification permission denied")
                }
            }
        }
    }
    
    private func setupNotificationCategories() {
        var goodAction: UNNotificationAction
        var badAction: UNNotificationAction
        var editAction: UNNotificationAction
        
        if #available(iOS 15.0, *) {
            goodAction = UNNotificationAction(
                identifier: "GOOD",
                title: "Good",
                options: [],
                icon: UNNotificationActionIcon(systemImageName: "hand.thumbsup")
            )
            
            badAction = UNNotificationAction(
                identifier: "BAD",
                title: "Bad",
                options: [.foreground],
                icon: UNNotificationActionIcon(systemImageName: "hand.thumbsdown")
            )
            
            editAction = UNNotificationAction(
                identifier: "EDIT_SPOT",
                title: "Edit Spot",
                options: [.foreground],
                icon: UNNotificationActionIcon(systemImageName: "pencil")
            )
        } else {
            goodAction = UNNotificationAction(
                identifier: "GOOD",
                title: "Good",
                options: []
            )
            
            badAction = UNNotificationAction(
                identifier: "BAD",
                title: "Bad",
                options: [.foreground]
            )
            
            editAction = UNNotificationAction(
                identifier: "EDIT_SPOT",
                title: "Edit Spot",
                options: [.foreground]
            )
        }
        
        let category = UNNotificationCategory(
            identifier: "LOCATION_REMINDER",
            actions: [goodAction, badAction, editAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("✅ Notification categories set up")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("Authorization status changed to: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("✅ Location permission: Always authorized - Background monitoring enabled")
            locationManager.pausesLocationUpdatesAutomatically = false
        case .authorizedWhenInUse:
            print("⚠️ Location permission: When in use only - Limited background monitoring")
        case .notDetermined:
            print("❓ Location permission: Not determined")
            break
        case .denied, .restricted:
            print("❌ Location permission: Denied or restricted")
        @unknown default:
            break
        }
        
        // Print currently monitored regions after auth change
        print("Currently monitoring \(locationManager.monitoredRegions.count) regions")
        for region in locationManager.monitoredRegions {
            print("  - Region: \(region.identifier)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("📍 Accuracy: \(location.horizontalAccuracy)m")
        print("📍 Timestamp: \(location.timestamp)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
    }

    private func sendNotificationForRegion(_ region: CLRegion, isEntry: Bool) {
        print("📤 Sending notification for region: \(region.identifier), isEntry: \(isEntry)")
        
        guard let context = managedObjectContext else {
            print("❌ No managed object context available")
            return
        }
        
        let request: NSFetchRequest<Spots> = Spots.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", region.identifier)
        
        do {
            let spots = try context.fetch(request)
            if let spot = spots.first {
                print("📍 Found spot: \(spot.nameOfLocation ?? "Unknown")")
                print("   notifyOnBoth: \(spot.notifyOnBoth)")
                print("   isEntry: \(isEntry)")
                
                // FIXED: Proper logic for when to notify
                let shouldNotify: Bool
                if spot.notifyOnBoth {
                    // Notify on both entry and exit
                    shouldNotify = true
                    print("✅ Will notify: notifyOnBoth is enabled")
                } else {
                    // Only notify on exit
                    shouldNotify = !isEntry
                    print(isEntry ? "❌ Skipping entry notification: notifyOnBoth is disabled" : "✅ Will notify: exit notification and notifyOnBoth is disabled")
                }
                
                if shouldNotify {
                    let title = spot.customNotificationTitle?.isEmpty == false ? spot.customNotificationTitle! : "Location Reminder"
                    let action = isEntry ? "arrived at" : "left"
                    let defaultBody = "You have \(action) \(spot.nameOfLocation ?? "your location")"
                    let body = spot.customNotificationBody?.isEmpty == false ? spot.customNotificationBody! : defaultBody
                    let spotName = spot.nameOfLocation ?? "Unknown Location"
                    
                    print("📢 Sending notification: \(title) - \(body)")
                    postLocalNotifications(title: title, body: body, spotId: region.identifier, spotName: spotName, isEntry: isEntry)
                    
                    LogManager.shared.addLog(
                        eventType: .notificationSent,
                        spotName: spotName,
                        message: "\(action.capitalized) notification sent: \(body)"
                    )
                } else {
                    print("📵 Notification skipped")
                }
            } else {
                print("❌ No spot found for region: \(region.identifier)")
            }
        } catch {
            print("❌ Error fetching spot data for notification: \(error)")
        }
    }

    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("❌ Region monitoring not available")
            return
        }
        
        // FIXED: Stop monitoring existing region with same identifier to prevent duplicates
        for existingRegion in locationManager.monitoredRegions {
            if existingRegion.identifier == identifier {
                print("🔄 Stopping existing monitoring for region: \(identifier)")
                locationManager.stopMonitoring(for: existingRegion)
                // Remove from active notifications tracking
                activeNotifications.removeValue(forKey: identifier)
            }
        }
        
        // Small delay to ensure the stop monitoring command is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var radius: Double = 100.0 // default radius
            
            if let context = self.managedObjectContext {
                let request: NSFetchRequest<Spots> = Spots.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", identifier)
                
                do {
                    let spots = try context.fetch(request)
                    if let spot = spots.first {
                        radius = Double(spot.distanceFromSpot)
                        print("Using radius from spot data: \(radius) meters for \(spot.nameOfLocation ?? "Unknown")")
                    }
                } catch {
                    print("Error fetching spot data for radius: \(error)")
                }
            }
            
            let maxDistance = self.locationManager.maximumRegionMonitoringDistance
            let finalRadius = min(radius, maxDistance)
            
            let region = CLCircularRegion(center: center, radius: finalRadius, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            print("🎯 Starting to monitor region: \(identifier)")
            print("   Center: \(center.latitude), \(center.longitude)")
            print("   Radius: \(finalRadius) meters")
            print("   Total monitored regions will be: \(self.locationManager.monitoredRegions.count + 1)")
            
            self.locationManager.startMonitoring(for: region)
            
            // Brief location update to help iOS establish the geofence
            self.locationManager.startUpdatingLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("✅ Successfully started monitoring region: \(region.identifier)")
        print("   Total monitored regions: \(locationManager.monitoredRegions.count)")
        
        // Request the current state of the region
        locationManager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Failed to monitor region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("📍 Currently INSIDE region: \(region.identifier)")
        case .outside:
            print("📍 Currently OUTSIDE region: \(region.identifier)")
        case .unknown:
            print("📍 Unknown state for region: \(region.identifier)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("🟢 ENTERED region: \(region.identifier)")
        print("   Time: \(Date())")
        print("   Thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Log the entry event
        if let spotName = getSpotName(for: region.identifier) {
            LogManager.shared.addLog(
                eventType: .entered,
                spotName: spotName,
                message: "Entered geofence area"
            )
        }
        
        sendNotificationForRegion(region, isEntry: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("🔴 EXITED region: \(region.identifier)")
        print("   Time: \(Date())")
        print("   Thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Log the exit event
        if let spotName = getSpotName(for: region.identifier) {
            LogManager.shared.addLog(
                eventType: .exited,
                spotName: spotName,
                message: "Exited geofence area"
            )
        }
        
        sendNotificationForRegion(region, isEntry: false)
    }
    
    private func getSpotName(for identifier: String) -> String? {
        guard let context = managedObjectContext else { return nil }
        
        let request: NSFetchRequest<Spots> = Spots.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", identifier)
        
        do {
            let spots = try context.fetch(request)
            return spots.first?.nameOfLocation
        } catch {
            print("Error fetching spot name: \(error)")
            return nil
        }
    }
    
    func postLocalNotifications(title: String, body: String, spotId: String? = nil, spotName: String, isEntry: Bool) {
        print("📢 Attempting to post notification:")
        print("   Title: \(title)")
        print("   Body: \(body)")
        print("   SpotId: \(spotId ?? "none")")
        
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notification for this spot if it exists
        if let spotId = spotId, let existingNotificationId = activeNotifications[spotId] {
            center.removePendingNotificationRequests(withIdentifiers: [existingNotificationId])
            center.removeDeliveredNotifications(withIdentifiers: [existingNotificationId])
            print("🗑️ Removed existing notification for spot: \(spotName)")
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "LOCATION_REMINDER"
        
        // Add notification icon based on entry/exit
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            // Create attachment with SF Symbol for entry/exit
            if let iconURL = createNotificationIcon(isEntry: isEntry) {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "icon", url: iconURL, options: nil)
                    content.attachments = [attachment]
                } catch {
                    print("❌ Failed to create notification attachment: \(error)")
                }
            }
        }
        
        // Get current badge count and increment
        UIApplication.shared.applicationIconBadgeNumber += 1
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber)
        
        // Add spot ID and name to userInfo for response tracking
        var userInfo: [String: Any] = ["spotName": spotName, "isEntry": isEntry]
        if let spotId = spotId {
            userInfo["spotId"] = spotId
        }
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let notificationId = UUID().uuidString
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        // Store the notification ID for this spot
        if let spotId = spotId {
            activeNotifications[spotId] = notificationId
        }

        center.add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error)")
            } else {
                print("✅ Notification scheduled successfully")
            }
        }
    }
    
    private func createNotificationIcon(isEntry: Bool) -> URL? {
        let iconName = isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
        let iconColor = isEntry ? UIColor.systemGreen : UIColor.systemOrange
        
        // Create an image from SF Symbol
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .medium)
        guard let symbolImage = UIImage(systemName: iconName, withConfiguration: config) else {
            print("❌ Failed to create symbol image")
            return nil
        }
        
        // Create colored version
        let coloredImage = symbolImage.withTintColor(iconColor, renderingMode: .alwaysOriginal)
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(iconName)_\(isEntry ? "entry" : "exit").png"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        guard let data = coloredImage.pngData() else {
            print("❌ Failed to convert image to PNG data")
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("❌ Failed to write image file: \(error)")
            return nil
        }
    }
}
