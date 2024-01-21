	//  EditSpotView.swift
	//  Lock
	//
	//  Created by Vaibhav Satishkumar on 5/12/23.
	//

import SwiftUI
import MapKit
import CoreData


struct EditSpotView: View {
	
	//let spot: Spots
	
	@Environment(\.managedObjectContext) var moc
	@Environment(\.dismiss) var dismiss
	var spot: FetchedResults<Spots>.Element
	
	let geocoder = CLGeocoder()
	@State private var notificationTitle = ""
	@State private var notificationBody = ""
	@State private var notifyOnBoth = false
	@State private var spotName = ""
	@State private var locationaddress = "Be sure to include the street name and number, zip code, city name, and name of country"
	@State private var coordinate = ""
	@State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.0003, longitudeDelta: 0.0003))
	@State var notifyMeters = Float(50)
	@State private var location: CLLocationCoordinate2D?
	func getLocation(from address: Binding<String>, completion: @escaping (_ location: CLLocationCoordinate2D?)-> Void) {
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressString(address.wrappedValue) { (placemarks, error) in
			guard let placemarks = placemarks,
				  let location = placemarks.first?.location?.coordinate else {
				completion(nil)
				return
			}
			completion(location)
		}
	}
	
	var body: some View {
		
			Form {
				Section{
					HStack{
						TextField("Name of Spot e.g. Home, School, Work", text: $spotName)
						Spacer()
						
					}
				} footer: {
					Text("This name will be what is listed in the Spots tab.")
				}
				.onAppear {
					notificationBody = spot.customNotificationBody ?? ""
					notificationTitle = spot.customNotificationTitle ?? ""
					notifyMeters = Float(spot.distanceFromSpot )
					spotName = spot.nameOfLocation ?? ""
					notifyOnBoth = spot.notifyOnBoth
					locationaddress = spot.address ?? ""
					region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude) ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.0003, longitudeDelta: 0.0003))
					
				}
				
				Section {
					TextField("Address or Coordinates", text: $locationaddress)
						.textContentType(.fullStreetAddress)
						.multilineTextAlignment(.leading)
					
					Map(coordinateRegion: $region, annotationItems: [
						Location(coordinate: location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
					],
						annotationContent: { locations in
						
						MapMarker(coordinate: location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),  tint: Color.purple)
						
					})
					
						.scaledToFill()
						.cornerRadius(9)
						.listRowInsets(EdgeInsets())
						.padding(10.0)
					
				} header: {
					Text("Enter your full address or location coordinates.")
				} footer: {
					Text("The address is converted and saved to your device as coordinates. On the map, verify that the information you have entered is correct.")
				}
				
				Section {
					Text("Notification Title:")
					TextField("Important Question:", text: $notificationTitle)
					Text("Notification Body:")
					TextField("Have you locked your house?", text: $notificationBody)
					
					
					
					
				} header: {
					Text("Customize the notification properties")
					
					
					
				} footer: {
					Text("Consider changing the default text to match your personal needs, such as remembering to turn off the stove or turning on the burglar alarm.")
				}
				
				
				
				Section{
					Toggle("Receive notifications when you leave and arrive.", isOn: $notifyOnBoth)
					Slider(value: $notifyMeters, in: 50...200, step: 2){}
					
				minimumValueLabel: {
					Text("50")
						.fontWeight(.thin)
				} maximumValueLabel: {
					Text("200")
						.fontWeight(.thin)
				}
					Group {
						Text("Notifications will be delivered after") +
						Text(" \(Int(notifyMeters)) ").foregroundColor(.blue) +
						Text("meters.")
					}
					
					
					
				} footer: {
					Text("By default, you will only be notified when you leave a spot.")
				}
				
				
				Section {
					Button("Save"){
						spot.latitude = location?.latitude ?? 0.0
						spot.longitude = location?.longitude ?? 0.0
						spot.nameOfLocation = spotName
						spot.customNotificationBody = notificationBody
						spot.customNotificationTitle = notificationTitle
						spot.distanceFromSpot = Int16(notifyMeters)
						spot.notifyOnBoth = notifyOnBoth
						try? moc.save()
						dismiss()
					}
					.disabled(spotName.isEmpty || locationaddress.isEmpty)
					.buttonStyle(threeDimensionalButton(lateralGradient: LinearGradient(
						gradient: Gradient(stops: [
							.init(color: .init(red: 0.3, green: 0.5, blue: 0.9),
								  location: 0.00001),
							.init(color: .init(red: 0.484, green: 0.7, blue: 1),
								  location: 0.1),
							.init(color: .init(red: 0.484, green: 0.7, blue: 1),
								  location: 0.9),
							.init(color: .init(red: 0.3, green: 0.5, blue: 0.9),
								  location: 0.99999)
						]),
						startPoint: .leading,
						endPoint: .trailing
					), flatGradient: LinearGradient(gradient: Gradient(colors: [.white,.init(red: 0.584, green: 0.749, blue: 1)]), startPoint: .top, endPoint: .bottom)))
					
					
					
				} footer: {
					Text("If you ever need to, you can edit the properties of this spot or even just delete it.")
					
					
				}.listRowBackground(Color.clear)
					.frame(height: 60)
				
					.onChange(of: locationaddress) { newValue in
						print("submitted")
						
						getLocation(from: $locationaddress) { coordinates in
							print(coordinates) // Print here
							location = coordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)// Assign to a local variable for further processing
							coordinate = "\(coordinates?.latitude ?? 0.0), \(coordinates?.longitude ?? 0.0)"
							region = MKCoordinateRegion(center: location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
						}
					}
				
				
				
				
				
			}
			
			.listStyle(InsetGroupedListStyle())
			.navigationTitle("Edit Spot Details")
			
			
		
		
	}
}

struct TextFieldClearButton: ViewModifier {
	@Binding var text: String
	
	func body(content: Content) -> some View {
		HStack {
			content
			
			if !text.isEmpty {
				Button(
					action: { self.text = "" },
					label: {
						Image(systemName: "delete.left")
							.foregroundColor(Color(UIColor.opaqueSeparator))
					}
				)
			}
		}
	}
}
