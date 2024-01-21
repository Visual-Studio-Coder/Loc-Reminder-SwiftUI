import UIKit
import CoreLocation
import WidgetKit
import UserNotifications
import SwiftUI
@MainActor
class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate {
	var locationManager = CLLocationManager()
	@Published var authorizationStatus: CLAuthorizationStatus?
	@FetchRequest(sortDescriptors: [
		SortDescriptor(\.nameOfLocation)
	]) var spots: FetchedResults<Spots>
	
	
	
	override init() {
		super.init()
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.delegate = self
		locationManager.distanceFilter = kCLDistanceFilterNone
		locationManager.delegate = self
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		switch manager.authorizationStatus {
		case .authorizedWhenInUse:  // Location services are available.
									// Insert code here of what should happen when Location services are authorized
			authorizationStatus = .authorizedWhenInUse
			locationManager.requestLocation()
			break
			
		case .restricted:  // Location services currently unavailable.
						   // Insert code here of what should happen when Location services are NOT authorized
			authorizationStatus = .restricted
			break
			
		case .denied:  // Location services currently unavailable.
					   // Insert code here of what should happen when Location services are NOT authorized
			authorizationStatus = .denied
			break
			
		case .notDetermined:        // Authorization not determined yet.
			authorizationStatus = .notDetermined
			manager.requestAlwaysAuthorization()
			break
			
		default:
			break
		}
        objectWillChange.send()
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
			// Insert code to handle location updates
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("error: \(error.localizedDescription)")
	}
	
	func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String ) {
			// Make sure the devices supports region monitoring.
		if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
				// Register the region.
			let maxDistance = locationManager.maximumRegionMonitoringDistance
			let region = CLCircularRegion(center: center,
										  radius: maxDistance, identifier: identifier)
			region.notifyOnEntry = true
			region.notifyOnExit = false
			
			locationManager.startMonitoring(for: region)
			
		}
	}
	func postLocalNotifications(moc: FetchedResults<Spots>.Element){
		
		
		
		
		
		let center = UNUserNotificationCenter.current()
		
		
		let content = UNMutableNotificationContent()
		content.title = moc.customNotificationTitle ?? ""
		content.body = moc.customNotificationBody ?? ""
		content.sound = UNNotificationSound.default
		content.categoryIdentifier = "Something"
		if #available(iOS 15.0, *) {
			content.interruptionLevel = .timeSensitive
		}
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
		
		let notificationRequest:UNNotificationRequest = UNNotificationRequest(identifier: "Region", content: content, trigger: trigger)
		
		center.add(notificationRequest, withCompletionHandler: { (error) in
			if let error = error {
					// Something went wrong
				print(error)
			}
			else{
				print("added")
			}
		})
	}
	
	
	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion, moc: FetchedResults<Spots>.Element) {
		print("Entered: \(region.identifier)")
		postLocalNotifications(moc: moc)
		locationManager.stopUpdatingLocation()
		locationManager.startUpdatingLocation()
		locationManager.stopMonitoring(for: region)
		locationManager.startMonitoring(for: region)
		locationManager.pausesLocationUpdatesAutomatically = false
		locationManager.allowsBackgroundLocationUpdates = true
	}
	
}
