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
    private var locationManager: CLLocationManager
    private var region: CLRegion?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    // Request location permissions
    func requestLocationPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Start monitoring a specific region
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String) {
        // Remove any existing region with the same identifier
        if let existingRegion = region {
            locationManager.stopMonitoring(existingRegion)
        }
        
        // Create a new region
        let geofenceRegion = CLCircularRegion(center: center, radius: 100, identifier: identifier)
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        
        // Start monitoring the new region
        locationManager.startMonitoring(geofenceRegion)
        region = geofenceRegion
        
        print("✅ Started monitoring region: \(identifier)")
    }
    
    // CLLocationManagerDelegate method - called when the device enters or exits a monitored region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("📍 Entered region: \(region.identifier)")
        // Handle region entry (e.g., send notification)
        sendNotificationForRegion(region, isEntry: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("📍 Exited region: \(region.identifier)")
        // Handle region exit (e.g., send notification)
        sendNotificationForRegion(region, isEntry: false)
    }
    
    // Request the current location
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
    
    // Handle location updates
    private var locationManagerDidUpdateLocations: (([CLLocation]) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManagerDidUpdateLocations?(locations)
    }
    
    private var managedObjectContext: NSManagedObjectContext?
    
    // Add this method to inject the context
    func setManagedObjectContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
        print("✅ Managed object context set in LocationDataManager")
    }
    
    // Update your notification sending method to use the context
    private func sendNotificationForRegion(_ region: CLRegion, isEntry: Bool) {
        print("📤 Sending notification for region: \(region.identifier), isEntry: \(isEntry)")
        
        guard let context = managedObjectContext else {
            print("❌ No managed object context available")
            return
        }
        
        // Now you can fetch the spot data using the context
        let request: NSFetchRequest<Spots> = Spots.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", region.identifier)
        
        do {
            let spots = try context.fetch(request)
            if let spot = spots.first {
                print("✅ Found spot: \(spot.nameOfLocation ?? "Unknown")")
                // Send your notification here using spot data
            } else {
                print("❌ No spot found for region: \(region.identifier)")
            }
        } catch {
            print("❌ Error fetching spot: \(error)")
        }
    }
}