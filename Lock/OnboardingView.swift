//
//  OnboardingView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/23/23.
//

import SwiftUI
import CoreLocation
import LocationAlwaysPermission
import UserNotifications
import PermissionsKit

struct OnboardingView: View {
	
	@State var showingAlert = false
	@State var showingAlert1 = false
	
	@AppStorage("shouldShowOnboarding") var dontShowOnboarding : Bool = false
	
	@AppStorage("fadeInOut") public var fadeInOut : Bool = false
	
	@StateObject var locationDataManager = LocationPermission()
	
	@State private var value = 1.0
	
	
	@State private var canTouchDown = true
	let impact = UIImpactFeedbackGenerator(style: .medium)
	@State private var selectedPage = 0
	
	@State private var isLocationAuthorized = false
	private let locationManager = CLLocationManager()
	
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		switch manager.authorizationStatus {
		case .authorizedWhenInUse:  // Location services are available.
			
			break
			
		case .restricted, .denied:  // Location services currently unavailable.
			
			break
			
		case .notDetermined:        // Authorization not determined yet.
			manager.requestAlwaysAuthorization()
			break
			
		default:
			break
		}
	}
	
	let coolView = AuroraView()
	
	var body: some View {
		
		
		
		ZStack{
			
			coolView
			
			
			TabView(selection: $selectedPage, content: {
					//onboarding page one
				VStack() {
					/*AuroraView()
					 .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
					 .edgesIgnoringSafeArea(.all)*/
					
					
					VStack{
						@ObservedObject var manager = MotionManager()
						ParallaxView()
							.scaledToFit()
							.scaleEffect(value)
				
							.frame(width: 400, height: 400)
						
						
						
						
						
						Text("Lock Reminder")
							.font(.largeTitle
								.bold())
							.foregroundColor(.white)
							.padding(10)
						Text("Never forget to lock your home ever again!")
							.frame(width: 332, height: 75)
							.scaledToFill()
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 20)
						
						
						Spacer()
						Button("Continue"){
							withAnimation(Animation.spring().delay(2)) { selectedPage += 1
							}
							
						}
						.padding([.leading, .bottom, .trailing], 20.0)
						.frame(width: 332, height: 75)
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
						.onAppear {
							withAnimation(.easeInOut(duration: 2)) {
								value = 1.1
							}
						}
						
						
						
						
						
						
						
					}
					
					.padding()
					
					
					
					
				}
				.tag(0)
					//onboarding page two
				VStack {
					/*AuroraView()
					 .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
					 .edgesIgnoringSafeArea(.all)*/
					
					
					VStack{
						
						@ObservedObject var manager = MotionManager()
						
						
						
						Image("location")
						
							.resizable()
							.cornerRadius(30)
							.shadow(color: Color(hue: 1.0, saturation: 0.303, brightness: 0.549), radius: 22)
							.scaledToFit()
							.padding(40)
							.frame(width: 400, height: 400)
							.modifier(ParallaxMotionModifier(manager: manager, magnitude: 15))
						
						Text("Enable Location")
							.font(.largeTitle
								.bold())
							.foregroundColor(.white)
							.padding(10)
						Text("Enable \"Always\" location access for notifications when you leave home, even when the app is closed.")
							.frame(width: 332, height: 75)
							.scaledToFill()
							.foregroundColor(.white)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 20)
						
						Spacer()
						Button("Authorize"){
							
							let authorized = Permission.locationAlways.authorized
							
							
							
							Permission.locationAlways.request {
								locationManager.stopUpdatingLocation()
							}
							
							let key = Permission.locationAlways.usageDescriptionKey
							
							
							if authorized {
								showingAlert = true
							}
							
							
							
						}.alert("Important message", isPresented: $showingAlert) {
							Button("OK", role: .cancel) { }
						}
						.padding([.leading, .bottom, .trailing], 20.0)
						.frame(width: 332, height: 75)
						.buttonStyle(threeDimensionalButton(lateralGradient: LinearGradient(
							gradient: Gradient(stops: [
								.init(color: Color(#colorLiteral(red: 0.1636346579, green: 0.5416366458, blue: 0.08888492733, alpha: 1)),
									  location: 0.00001),
								.init(color: Color(#colorLiteral(red: 0.5286380649, green: 0.9115514159, blue: 0.5707022548, alpha: 1)),
									  location: 0.1),
								.init(color: Color(#colorLiteral(red: 0.5286380649, green: 0.9115514159, blue: 0.5707022548, alpha: 1)),
									  location: 0.9),
								.init(color: Color(#colorLiteral(red: 0.1636346579, green: 0.5416366458, blue: 0.08888492733, alpha: 1)),
									  location: 0.99999)
							]),
							startPoint: .leading,
							endPoint: .trailing
						), flatGradient: LinearGradient(gradient: Gradient(colors: [.white, Color(#colorLiteral(red: 0.5279352069, green: 0.9114217162, blue: 0.5712119341, alpha: 0.7654180464))]), startPoint: .top, endPoint: .bottom)))
						.onAppear {
							withAnimation(.easeInOut(duration: 2)) {
								value = 1.1
							}
						}
						
						
						
						
						
						
						
						
					}
					.padding()
					
				}
				.tag(1)
					//onboarding page three
				VStack{
					@ObservedObject var manager = MotionManager()
					Image("notification")
					
						.resizable()
						.foregroundColor(.red)
					
						.cornerRadius(30)
						.shadow(color: .gray, radius: 22)
						.scaledToFit()
						.padding(40)
						.frame(width: 400, height: 400)
						.modifier(ParallaxMotionModifier(manager: manager, magnitude: 15))
					
					Text("Enable Notifications")
						.font(.largeTitle
							.bold())
						.foregroundColor(.white)
						.padding(10)
					Text("Lock Reminder alerts you by delivering notifications if a location based event occurs.")
						.frame(width: 332, height: 75)
						.scaledToFill()
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 20)
					Spacer()
					Button("Continue"){
						UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
							if success {
								print("All set!")
								
								withAnimation(Animation.spring().delay(2)) { selectedPage += 1
								}
								
								//showingAlert1 = true
							} else if let error = error {
								print(error.localizedDescription)
								showingAlert1 = true
							}
							
							
								
						}
						
						
						
					}.alert(isPresented: $showingAlert1) {
						Alert(
							title: Text("Current Location Not Available"),
							message: Text("Your current location can’t be " +
										  "determined at this time.")
						)
					}
					
					
					.padding([.leading, .bottom, .trailing], 20.0)
					.frame(width: 332, height: 75)
					.tint(.green)
					.buttonStyle(threeDimensionalButton(lateralGradient: LinearGradient(
						gradient: Gradient(stops: [
							.init(color: Color(#colorLiteral(red: 0.1636346579, green: 0.5416366458, blue: 0.08888492733, alpha: 1)),
								  location: 0.00001),
							.init(color: Color(#colorLiteral(red: 0.5286380649, green: 0.9115514159, blue: 0.5707022548, alpha: 1)),
								  location: 0.1),
							.init(color: Color(#colorLiteral(red: 0.5286380649, green: 0.9115514159, blue: 0.5707022548, alpha: 1)),
								  location: 0.9),
							.init(color: Color(#colorLiteral(red: 0.1636346579, green: 0.5416366458, blue: 0.08888492733, alpha: 1)),
								  location: 0.99999)
						]),
						startPoint: .leading,
						endPoint: .trailing
					), flatGradient: LinearGradient(gradient: Gradient(colors: [.white, Color(#colorLiteral(red: 0.5279352069, green: 0.9114217162, blue: 0.5712119341, alpha: 0.7654180464))]), startPoint: .top, endPoint: .bottom)))
					.onAppear {
						withAnimation(.easeInOut(duration: 2)) {
							value = 1.1
						}
					}
					
					
					
				}
				.padding()
				.tag(2)
					//onboarding page four
				VStack{
					
					@ObservedObject var manager = MotionManager()
					Image("LockReminderHappyFace")
						.resizable()
						.foregroundColor(.white)
						.shadow(color: .white, radius: 10)
						.cornerRadius(30)
						.shadow(color: .gray, radius: 1)
						.scaledToFit()
						.padding(40)
						.frame(width: 400, height: 400)
						.modifier(ParallaxMotionModifier(manager: manager, magnitude: 15))
					
					Text("Setup Complete")
						.font(.largeTitle
							.bold())
						.foregroundColor(.white)
						.padding(10)
					Text("You are ready to get started. Click dismiss and head to the \"Spots\" tab to add your first spot!")
						.frame(width: 332, height: 75)
						.scaledToFill()
						.foregroundColor(.white)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 20)
					Spacer()
					
					Button("Dismiss"){
						
						
						dontShowOnboarding = true
						self
							.opacity(1)
						
						
					}
					.padding([.leading, .bottom, .trailing], 20.0)
					.frame(width: 332, height: 75)
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
					.onAppear {
						withAnimation(.easeInOut(duration: 2)) {
							value = 1.1
						}
					}
					
					
					
				}
				.padding()
				.tag(3)
				
				
			})
			.tabViewStyle(PageTabViewStyle())
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
			.edgesIgnoringSafeArea(.all)
		}
		
		
	}
	
}
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
