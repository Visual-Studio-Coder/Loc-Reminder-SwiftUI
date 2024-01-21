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
    
    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss
    
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
                    Text("By default, you will only be notified when you leave a spot.")
                }
                
                
                Section {
                    Button("Save"){
                        let newSpot = Spots(context: moc)
                        newSpot.id = UUID()
                        newSpot.nameOfLocation = spotName
                        newSpot.notifyOnBoth = notifyOnBoth
                        newSpot.address = locationaddress
                        newSpot.distanceFromSpot = Int16(notifyMeters)
                        newSpot.customNotificationTitle = notificationTitle
                        newSpot.customNotificationBody = notificationBody
                        newSpot.longitude = location!.longitude
                        newSpot.latitude = location!.latitude
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
                

                
                
                
                
                
            }
            
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Spot Details")
            
            
        }
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
}

struct AddSpotView_Previews: PreviewProvider {
    static var previews: some View {
        AddSpotView()
        
    }
}
struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
