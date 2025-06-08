/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  LocationDataManager.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 5/12/23.
//

import Foundation
import CoreLocation
import UserNotifications
import SwiftUI

class LocationDataManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    private var managedObjectContext: NSManagedObjectContext?
    
    // State tracking with UserDefaults persistence
    private var currentRegionStates: [String: Bool] = [:]
    private var lastRegionEventProcessingTime: [String: Date] = [:]
    private let minTimeBetweenEventProcessingForRegion: TimeInterval = 15.0

    override init() {
        super.init()
        locationManager.delegate = self
        loadPersistedState() // Load state from UserDefaults
        setupLocationManager()
    }
    
    // MARK: - State Persistence
    private func loadPersistedState() {
        // Load region states
        if let stateData = UserDefaults.standard.data(forKey: "currentRegionStates") {
            do {
                currentRegionStates = try JSONDecoder().decode([String: Bool].self, from: stateData)
                print("📱 Loaded persisted region states: \(currentRegionStates)")
            } catch {
                print("❌ Failed to load region states: \(error)")
                currentRegionStates = [:]
            }
        }
        
        // Load last processing times
        if let timeData = UserDefaults.standard.data(forKey: "lastRegionEventProcessingTime") {
            do {
                lastRegionEventProcessingTime = try JSONDecoder().decode([String: Date].self, from: timeData)
                print("📱 Loaded persisted processing times: \(lastRegionEventProcessingTime)")
            } catch {
                print("❌ Failed to load processing times: \(error)")
                lastRegionEventProcessingTime = [:]
            }
        }
    }
    
    private func savePersistedState() {
        // Save region states
        do {
            let stateData = try JSONEncoder().encode(currentRegionStates)
            UserDefaults.standard.set(stateData, forKey: "currentRegionStates")
            print("💾 Saved region states to UserDefaults")
        } catch {
            print("❌ Failed to save region states: \(error)")
        }
        
        // Save last processing times
        do {
            let timeData = try JSONEncoder().encode(lastRegionEventProcessingTime)
            UserDefaults.standard.set(timeData, forKey: "lastRegionEventProcessingTime")
            print("💾 Saved processing times to UserDefaults")
        } catch {
            print("❌ Failed to save processing times: \(error)")
        }
    }

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Consider .kCLLocationAccuracyHundredMeters for geofencing
        locationManager.distanceFilter = kCLDistanceFilterNone // Not strictly needed for geofencing alone
        
        // Request permissions
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("❌ Location access denied or restricted")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("✅ Location permission: Always authorized - Background monitoring enabled")
        @unknown default:
            break
        }
    }
    
    func setManagedObjectContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
        print("✅ Managed object context set in LocationDataManager")
        // After context is set, and spots might be loaded, refresh region states
        refreshAllCurrentlyMonitoredRegionStates()
    }
    
    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let regionId = region.identifier
        let eventTime = Date()
        print("🟢 System reported ENTER for region: \(regionId) at \(eventTime)")
        print("   State before processing: currentRegionStates[\(regionId)] = \(currentRegionStates[regionId].map { String(describing: $0) } ?? "nil"), lastEventTime: \(lastRegionEventProcessingTime[regionId]?.description ?? "nil")")

        // GUARD 1: Already recorded as INSIDE?
        if let currentState = currentRegionStates[regionId], currentState == true {
            print("   ⚠️ Already recorded as INSIDE. Ignoring redundant system enter event for \(regionId).")
            return
        }

        // GUARD 2: An event (enter or exit) was processed too recently for this region?
        if let lastProcessingTime = lastRegionEventProcessingTime[regionId] {
            let timeSinceLastProcessing = eventTime.timeIntervalSince(lastProcessingTime)
            if timeSinceLastProcessing < minTimeBetweenEventProcessingForRegion {
                print("   ⚠️ Event for \(regionId) processed \(Int(timeSinceLastProcessing))s ago. Suppressing this rapid ENTER event.")
                // Still update our belief of the state if system says we entered
                currentRegionStates[regionId] = true
                savePersistedState() // Persist the state change
                DispatchQueue.main.async {
                    LogManager.shared.addLog(
                        eventType: .entered,
                        spotName: self.getSpotName(for: regionId) ?? regionId,
                        message: "Entered geofence (rapid system event, notification suppressed, \(Int(timeSinceLastProcessing))s)"
                    )
                }
                return
            }
        }

        print("   ✅ Processing ENTER for region: \(regionId)")
        currentRegionStates[regionId] = true // Update state to inside
        lastRegionEventProcessingTime[regionId] = eventTime // Record time of this event processing
        savePersistedState() // Persist the state changes

        DispatchQueue.main.async {
            self.sendNotification(for: region, isEntry: true)
            LogManager.shared.addLog(
                eventType: .entered,
                spotName: self.getSpotName(for: regionId) ?? regionId,
                message: "Entered geofence area"
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let regionId = region.identifier
        let eventTime = Date()
        print("🔴 System reported EXIT for region: \(regionId) at \(eventTime)")
        print("   State before processing: currentRegionStates[\(regionId)] = \(currentRegionStates[regionId].map { String(describing: $0) } ?? "nil"), lastEventTime: \(lastRegionEventProcessingTime[regionId]?.description ?? "nil")")

        // GUARD 1: Already recorded as OUTSIDE?
        if let currentState = currentRegionStates[regionId], currentState == false {
            print("   ⚠️ Already recorded as OUTSIDE. Ignoring redundant system exit event for \(regionId).")
            return
        }

        // GUARD 2: An event (enter or exit) was processed too recently for this region?
        if let lastProcessingTime = lastRegionEventProcessingTime[regionId] {
            let timeSinceLastProcessing = eventTime.timeIntervalSince(lastProcessingTime)
            if timeSinceLastProcessing < minTimeBetweenEventProcessingForRegion {
                print("   ⚠️ Event for \(regionId) processed \(Int(timeSinceLastProcessing))s ago. Suppressing this rapid EXIT event.")
                // Still update our belief of the state
                currentRegionStates[regionId] = false
                savePersistedState() // Persist the state change
                DispatchQueue.main.async {
                    LogManager.shared.addLog(
                        eventType: .exited,
                        spotName: self.getSpotName(for: regionId) ?? regionId,
                        message: "Exited geofence (rapid system event, notification suppressed, \(Int(timeSinceLastProcessing))s)"
                    )
                }
                return
            }
        }

        print("   ✅ Processing EXIT for region: \(regionId)")
        currentRegionStates[regionId] = false // Update state to outside
        lastRegionEventProcessingTime[regionId] = eventTime // Record time of this event processing
        savePersistedState() // Persist the state changes

        DispatchQueue.main.async {
            self.sendNotification(for: region, isEntry: false)
            LogManager.shared.addLog(
                eventType: .exited,
                spotName: self.getSpotName(for: regionId) ?? regionId,
                message: "Exited geofence area"
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let regionId = region.identifier
        let previousInternalStateDescription = currentRegionStates[regionId].map { $0 ? "INSIDE" : "OUTSIDE" } ?? "nil"
        var newInternalStateValue: Bool?
        let systemStateDescription: String

        switch state {
        case .inside:
            systemStateDescription = "INSIDE"
            newInternalStateValue = true
        case .outside:
            systemStateDescription = "OUTSIDE"
            newInternalStateValue = false
        case .unknown:
            systemStateDescription = "UNKNOWN"
            // When system reports UNKNOWN, we generally don't want to change our current belief,
            // unless our current belief is nil (i.e., we have no idea).
            if currentRegionStates[regionId] == nil {
                 print("ℹ️ Determined state for region \(regionId): UNKNOWN. Internal state was nil. No change.")
            } else {
                 print("ℹ️ Determined state for region \(regionId): UNKNOWN. Previous internal state: \(previousInternalStateDescription). Retaining previous state.")
            }
            return // Explicitly do not change state based on UNKNOWN if we have a prior state.
        @unknown default:
            systemStateDescription = "UNHANDLED_SYSTEM_STATE"
            print("ℹ️ Determined state for region \(regionId): \(systemStateDescription). Previous internal state: \(previousInternalStateDescription). No change.")
            return
        }
        
        if currentRegionStates[regionId] != newInternalStateValue {
            print("ℹ️ Determined state for region \(regionId): \(systemStateDescription). Previous internal state: \(previousInternalStateDescription). Updating currentRegionStates.")
            currentRegionStates[regionId] = newInternalStateValue
            savePersistedState() // Persist the state change
        } else {
            print("ℹ️ Determined state for region \(regionId): \(systemStateDescription). Matches current internal state \(previousInternalStateDescription). No change.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Monitoring failed for region: \(region?.identifier ?? "unknown") with error: \(error.localizedDescription)")
        if let regionId = region?.identifier {
            LogManager.shared.addLog(eventType: .exited, spotName: getSpotName(for: regionId) ?? regionId, message: "Monitoring failed: \(error.localizedDescription)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Authorization status changed to: \(status.rawValue)")
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location permission sufficient. Refreshing region states.")
            refreshAllCurrentlyMonitoredRegionStates()
        case .denied, .restricted:
            print("❌ Location access denied or restricted. Clearing monitored regions.")
            locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
            currentRegionStates.removeAll()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            print("❓ Location permission: Unknown status")
        }
        updateMonitoringStatusPrint() // Just for logging
    }

    private func updateMonitoringStatusPrint() {
        let monitoredCount = locationManager.monitoredRegions.count
        print("Currently monitoring \(monitoredCount) regions in CLLocationManager.")
        locationManager.monitoredRegions.forEach { region in
            print("  - System monitoring: \(region.identifier), State in app: \(currentRegionStates[region.identifier].map { $0 ? "INSIDE" : "OUTSIDE" } ?? "UNKNOWN")")
        }
    }
    
    func refreshAllCurrentlyMonitoredRegionStates() {
        print("🔄 Refreshing states for all CLLocationManager monitored regions...")
        for region in locationManager.monitoredRegions {
            print("   Requesting state for \(region.identifier)")
            locationManager.requestState(for: region)
        }
    }

    // This method's responsibility is ONLY to check spot settings and fire UNNotification if allowed.
    // It does NOT handle time-based suppression; that's done by the callers (didEnter/didExit).
    private func sendNotification(for region: CLRegion, isEntry: Bool) {
        print("📤 Evaluating notification for region: \(region.identifier), isEntry: \(isEntry)")
        
        guard let context = managedObjectContext else {
            print("❌ No managed object context available for notification evaluation")
            return
        }
        
        let request: NSFetchRequest<Spots> = Spots.fetchRequest()
        guard let regionUUID = UUID(uuidString: region.identifier) else {
            print("❌ Invalid region identifier (not a UUID): \(region.identifier)")
            return
        }
        request.predicate = NSPredicate(format: "id == %@", regionUUID as CVarArg)
        
        do {
            let spots = try context.fetch(request)
            guard let spot = spots.first else {
                print("❌ No spot found for region: \(region.identifier) during notification evaluation.")
                return
            }
            
            print("📍 Found spot: \(spot.nameOfLocation ?? "Unknown") for notification evaluation.")
            // Assuming Spots entity has notifyOnEntry and notifyOnExit (Bool)
            // Or a single notifyOnBoth (Bool)
            print("   Spot settings: NotifyOnEntry: \(spot.notifyOnEntry), NotifyOnExit: \(spot.notifyOnExit). Current event isEntry: \(isEntry)")

            var shouldSendThisNotification = false
            if isEntry && spot.notifyOnEntry { // If your entity uses notifyOnBoth: spot.notifyOnBoth
                shouldSendThisNotification = true
            } else if !isEntry && spot.notifyOnExit { // If your entity uses notifyOnBoth: spot.notifyOnBoth || spot.notifyOnExit (common for exit)
                shouldSendThisNotification = true
            }
            // Example if using notifyOnBoth:
            // let shouldSendThisNotification = (isEntry && spot.notifyOnBoth) || (!isEntry && (spot.notifyOnBoth || spot.notifyOnExit)) // Common: notify on exit always if notifyOnExit is true, or if notifyOnBoth is true.

            if shouldSendThisNotification {
                print("✅ Will send UNNotification for \(region.identifier): \(isEntry ? "entry" : "exit")")
                
                let title = spot.customNotificationTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? spot.customNotificationTitle! : (spot.nameOfLocation ?? "Location Reminder")
                let bodyDefault = isEntry ? "You've arrived at \(spot.nameOfLocation ?? "your location")." : "Did you remember your task at \(spot.nameOfLocation ?? "your location")?"
                let body = spot.customNotificationBody?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? spot.customNotificationBody! : bodyDefault
                
                // Call the global helper to actually send the UNNotification
                sendLocationNotification(title: title, body: body, spotId: region.identifier, spotName: spot.nameOfLocation ?? "Unknown", isEntry: isEntry)
                
                // Log that a UNNotification was sent
                LogManager.shared.addLog(
                    eventType: .notificationSent,
                    spotName: spot.nameOfLocation ?? "Unknown Location",
                    message: "\(isEntry ? "Entry" : "Exit") UNNotification: \(title)"
                )
            } else {
                print("❌ Skipping UNNotification for \(region.identifier) based on spot settings (isEntry: \(isEntry), notifyOnEntry: \(spot.notifyOnEntry), notifyOnExit: \(spot.notifyOnExit)).")
            }
            
        } catch {
            print("❌ Error fetching spot for notification evaluation: \(error.localizedDescription)")
        }
    }
    
    func requestLocationPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String, radius: CLLocationDistance = 100.0, notifyOnEntry: Bool, notifyOnExit: Bool) {
        // Stop monitoring if this region (identifier) already exists
        if let existingRegion = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) {
            print("   Stopping monitoring for existing region: \(identifier)")
            locationManager.stopMonitoring(existingRegion)
            currentRegionStates.removeValue(forKey: identifier) // Clear old state
            lastRegionEventProcessingTime.removeValue(forKey: identifier) // Clear old processing time
            savePersistedState() // Persist the cleanup
        }
        
        let geofenceRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        geofenceRegion.notifyOnEntry = notifyOnEntry
        geofenceRegion.notifyOnExit = notifyOnExit
        
        locationManager.startMonitoring(geofenceRegion)
        print("✅ Started monitoring region: \(identifier) (Entry: \(notifyOnEntry), Exit: \(notifyOnExit)). Requesting initial state.")
        locationManager.requestState(for: geofenceRegion)
    }
    
    func requestCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        locationManager.requestLocation()
        
        // CLLocationManagerDelegate method - called with the location update
        self.locationManagerDidUpdateLocations = { locations in
            guard let location = locations.last else {
                completion(nil)
                return
            }
            
            completion(location.coordinate)
        }
    }
    
    private var locationManagerDidUpdateLocations: (([CLLocation]) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManagerDidUpdateLocations?(locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed with error: \(error)")
    }
    
    private func getSpotName(for regionId: String) -> String? {
        guard let context = managedObjectContext else { return nil }
        
        let request: NSFetchRequest<Spots> = Spots.fetchRequest()
        guard let regionUUID = UUID(uuidString: regionId) else { return nil }
        request.predicate = NSPredicate(format: "id == %@", regionUUID as CVarArg)
        
        do {
            let spots = try context.fetch(request)
            return spots.first?.nameOfLocation
        } catch {
            print("❌ Error fetching spot name: \(error)")
            return nil
        }
    }
}

// Global helper function (ensure this is accessible, e.g. top-level or in a shared utility file)
func sendLocationNotification(title: String, body: String, spotId: String, spotName: String, isEntry: Bool) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    content.categoryIdentifier = "LOCATION_REMINDER"
    content.userInfo = [
        "spotId": spotId,
        "spotName": spotName,
        "isEntry": isEntry, // Useful for context if needed
        "isTestNotification": false
    ]
    content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Immediate trigger

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("❌ Error scheduling notification: \(error.localizedDescription)")
        } else {
            print("✅ Notification scheduled: \(title)")
        }
    }
}