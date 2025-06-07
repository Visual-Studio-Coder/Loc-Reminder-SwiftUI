/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  AddSpotView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 5/12/23.
//

import SwiftUI
import MapKit
import SFSymbolsPicker
import EmojiPicker
import CoreLocation


struct AddSpotView: View {
    @Environment(\.managedObjectContext) private var moc // Use environment context
    @EnvironmentObject private var locationManager: LocationDataManager // Use environment object
    @Environment(\.dismiss) private var dismiss
    
    // REMOVE any lines like these if they exist:
    // @StateObject private var dataController = DataController()
    // @StateObject private var locationManager = LocationDataManager()
    
    let geocoder = CLGeocoder()
    @State private var notificationTitle = ""
    @State private var notificationBody = ""
    @State private var notifyOnBoth = false
    @State private var spotName = ""
    @State private var locationaddress = ""
    @State private var coordinate = ""
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.0003, longitudeDelta: 0.0003))
    @State var notifyMeters = Float(50)
    @State private var location: CLLocationCoordinate2D?
    @State private var isUserInteractingWithMap = false
    @State private var geocodingWorkItem: DispatchWorkItem?
    func getLocation(from address: Binding<String>, completion: @escaping (_ location: CLLocationCoordinate2D?)-> Void) {
        let geocoder = CLGeocoder()
        print("🗺️ Geocoding address: '\(address.wrappedValue)'")
        
        geocoder.geocodeAddressString(address.wrappedValue) { (placemarks, error) in
            if let error = error {
                print("❌ Geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemarks = placemarks, !placemarks.isEmpty else {
                print("❌ No placemarks found for address: '\(address.wrappedValue)'")
                completion(nil)
                return
            }
            
            guard let location = placemarks.first?.location?.coordinate else {
                print("❌ No coordinate found in placemarks")
                completion(nil)
                return
            }
            
            print("✅ Geocoding successful:")
            print("   Address: '\(address.wrappedValue)'")
            print("   Latitude: \(location.latitude)")
            print("   Longitude: \(location.longitude)")
            completion(location)
        }
    }
   
    @State private var icon = "l1.rectangle.roundedbottom"
    
    @State private var isPresented = false

    var body: some View {
        NavigationView {
            Form {
                Section{
                    HStack{
                        TextField("Name of Spot e.g. Home, School, Work", text: $spotName)
                    }
                    /*Button(action: {
                        withAnimation {
                            isPresented.toggle()
                        }
                    }, label: {
                        HStack {
                            Text("Press Here")
                            Spacer()
                            Image(systemName: icon)
                        }
                    })
                    
                    SFSymbolsPicker(isPresented: $isPresented, icon: $icon, category: .none, axis: .vertical, haptic: true)
                */
                    
                } footer: {
                    Text("This name will be what is listed in the Spots tab.")
                }
                
                Section {
                    TextField("Enter Address or Coordinates", text: $locationaddress)
                        .textContentType(.fullStreetAddress)
                        
                    
                    
                    ZStack{
                        
                        if location?.latitude == 0 && location?.longitude == 0 {
                            Text("No Location Found")
                                .bold()
                                .foregroundColor(.red)
                        }
                        
                        Map(coordinateRegion: .constant(region), annotationItems: [
                            MapLocation(coordinate: location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
                        ],
                            annotationContent: { mapLocation in
                            
                            MapMarker(coordinate: mapLocation.coordinate, tint: Color.purple)
                            
                        })
                        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                            // Prevent map updates when keyboard appears
                            isUserInteractingWithMap = true
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                            // Allow map updates when keyboard disappears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isUserInteractingWithMap = false
                            }
                        }
                        .scaledToFill()
                        .cornerRadius(9)
                        .listRowInsets(EdgeInsets())
                        .padding(10.0)
                        
                    }
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
                    Text(notifyOnBoth ? "You will be notified when you leave AND arrive at a spot. Toggle the switch above to make changes." : "You will only be notified when you leave a spot. Toggle the switch above to make changes.")
                }
                
                
                Section {
                    Button("Save"){
                        guard let location = location else { 
                            print("❌ No location available for saving")
                            return 
                        }
                        
                        // Add validation for valid coordinates
                        guard location.latitude != 0.0 && location.longitude != 0.0 else {
                            print("❌ Invalid coordinates (0,0) - cannot save spot")
                            return
                        }
                        
                        print("💾 Saving spot with coordinates:")
                        print("   Name: \(spotName)")
                        print("   Address: \(locationaddress)")
                        print("   Latitude: \(location.latitude)")
                        print("   Longitude: \(location.longitude)")
                        print("   Distance: \(notifyMeters)")
                        
                        let newSpot = Spots(context: moc)
                        newSpot.id = UUID()
                        newSpot.nameOfLocation = spotName
                        newSpot.notifyOnBoth = notifyOnBoth
                        newSpot.address = locationaddress
                        newSpot.distanceFromSpot = Int16(notifyMeters)
                        newSpot.customNotificationTitle = notificationTitle
                        newSpot.customNotificationBody = notificationBody
                        newSpot.longitude = location.longitude
                        newSpot.latitude = location.latitude
                        
                        print("📝 Spot data set:")
                        print("   ID: \(newSpot.id?.uuidString ?? "No ID")")
                        print("   Saved Latitude: \(newSpot.latitude)")
                        print("   Saved Longitude: \(newSpot.longitude)")
                        
                        // Start monitoring this location using the shared instance
                        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                        locationManager.monitorRegionAtLocation(center: coordinate, identifier: newSpot.id!.uuidString)
                        
                        do {
                            try moc.save()
                            print("✅ Spot saved successfully")
                        } catch {
                            print("❌ Error saving spot: \(error)")
                        }
                        dismiss()
                    }
                    .disabled(spotName.isEmpty || locationaddress.isEmpty || location == nil || (location?.latitude == 0.0 && location?.longitude == 0.0))
                    .opacity(spotName.isEmpty || locationaddress.isEmpty || location == nil || (location?.latitude == 0.0 && location?.longitude == 0.0) ? 0.4 : 1)
                    .foregroundStyle(spotName.isEmpty || locationaddress.isEmpty || location == nil || (location?.latitude == 0.0 && location?.longitude == 0.0) ? Color.gray : Color.clear)
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
                

                
                
                
                
                
            }
            .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    dismiss()
                                }
                            }
                            
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    guard let location = location else { 
                                        print("❌ No location available for saving (toolbar)")
                                        return 
                                    }
                                    
                                    // Add validation for valid coordinates
                                    guard location.latitude != 0.0 && location.longitude != 0.0 else {
                                        print("❌ Invalid coordinates (0,0) - cannot save spot (toolbar)")
                                        return
                                    }
                                    
                                    print("💾 Saving spot via toolbar with coordinates:")
                                    print("   Latitude: \(location.latitude)")
                                    print("   Longitude: \(location.longitude)")
                                    
                                    let newSpot = Spots(context: moc)
                                    newSpot.id = UUID()
                                    newSpot.nameOfLocation = spotName
                                    newSpot.notifyOnBoth = notifyOnBoth
                                    newSpot.address = locationaddress
                                    newSpot.distanceFromSpot = Int16(notifyMeters)
                                    newSpot.customNotificationTitle = notificationTitle
                                    newSpot.customNotificationBody = notificationBody
                                    newSpot.longitude = location.longitude
                                    newSpot.latitude = location.latitude
                                    
                                    // Start monitoring this location using the shared instance
                                    let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                    locationManager.monitorRegionAtLocation(center: coordinate, identifier: newSpot.id!.uuidString)
                                    
                                    do {
                                        try moc.save()
                                        print("✅ Spot saved successfully via toolbar")
                                    } catch {
                                        print("❌ Error saving spot via toolbar: \(error)")
                                    }
                                    dismiss()
                                }
                                .disabled(spotName.isEmpty || locationaddress.isEmpty || location == nil || (location?.latitude == 0.0 && location?.longitude == 0.0))
                            }
                        }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Spot Details")
            
            
        }
        .onChange(of: locationaddress) { newValue in
            print("📝 Address changed to: '\(newValue)'")
            
            // Cancel any existing geocoding work
            geocodingWorkItem?.cancel()
            
            // Only geocode if the address is not empty and has reasonable length
            guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  newValue.count > 5 else {
                print("⚠️ Address too short or empty, skipping geocoding")
                DispatchQueue.main.async {
                    self.location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                }
                return
            }
            
            // Create new work item with debouncing
            let workItem = DispatchWorkItem {
                self.getLocation(from: self.$locationaddress) { coordinates in
                    DispatchQueue.main.async {
                        if let coordinates = coordinates {
                            print("📍 Setting location to: \(coordinates.latitude), \(coordinates.longitude)")
                            self.location = coordinates
                            self.coordinate = "\(coordinates.latitude), \(coordinates.longitude)"
                            
                            // Always update region when we get valid coordinates
                            self.region = MKCoordinateRegion(
                                center: coordinates,
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            )
                            print("📍 Region updated to: \(coordinates)")
                        } else {
                            print("❌ Geocoding failed, setting location to 0,0")
                            self.location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                            self.coordinate = "0.0, 0.0"
                            self.region = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }
                }
            }
            
            // Store the work item and execute after delay
            geocodingWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        }
        
        
    }
}

struct AddSpotView_Previews: PreviewProvider {
    static var previews: some View {
        AddSpotView()
        
    }
}
//struct Location: Identifiable {
//    let id = UUID()
//    let coordinate: CLLocationCoordinate2D
//}
struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
