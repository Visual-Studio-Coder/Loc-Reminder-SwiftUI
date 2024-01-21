import CoreLocation


class LocationPermission:NSObject, ObservableObject, CLLocationManagerDelegate {
	
	@Published var authorizationStatus : CLAuthorizationStatus = .notDetermined
	private let locationManager = CLLocationManager()
	@Published var coordinate : CLLocationCoordinate2D?
	
	override init() {
		super.init()
		locationManager.delegate=self
		locationManager.desiredAccuracy=kCLLocationAccuracyBest
		//locationManager.startUpdatingLocation()
	}
	
	func requestLocationPermission()  {
		locationManager.requestAlwaysAuthorization()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		authorizationStatus = manager.authorizationStatus
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else {return}
		
		coordinate = location.coordinate
	}
	
	
}
