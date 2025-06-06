/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  OnboardingView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/23/23.
//

import SwiftUI
import CoreLocation
import NotificationPermission
import UserNotifications
import PermissionsKit

struct OnboardingView: View {
	@State var showingAlert = false
	@State var showingAlert1 = false
    @State var showingAlert2 = false
	@AppStorage("shouldShowOnboarding") var dontShowOnboarding : Bool = false
	@AppStorage("fadeInOut") public var fadeInOut : Bool = false
	@StateObject var locationDataManager = LocationDataManager()
	@State private var value = 1.0
	@State private var canTouchDown = true
	let impact = UIImpactFeedbackGenerator(style: .medium)
	@State private var selectedPage = 0
	
	// Clean location permission tracking
	@State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined
	@State private var locationManager = CLLocationManager()
	@State private var locationButtonText: String = "Enable"
	@State private var notificationButtonText: String = "Enable"

	let coolView = AuroraView()
	
	var body: some View {
		ZStack{
			coolView
			TabView(selection: $selectedPage, content: {
				VStack() { // Welcome Page - Tag 0
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

				VStack { // Location Permission Page - Tag 1
					VStack{
						@ObservedObject var manager = MotionManager() // Assuming a new instance or pass one
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
                        Button(action: {
                            handleLocationButtonTap()
                        }){
                            HStack{
                                Text(locationButtonText)
                                if locationButtonText == "Enable" {
                                    Image(systemName: "location.fill")
                                }
                            }
                        }.alert(isPresented: $showingAlert) {
                            Alert(
                                title: Text("Always Location Permission Required"),
                                message: Text("Please enable the \"Always\" location permissions in settings so that this app can work even when it is not opened."),
                                primaryButton: .default(Text("Enable in Settings"), action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }),
                                secondaryButton: .cancel()
                            )
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
                            checkLocationPermissionStatus()
							withAnimation(.easeInOut(duration: 2)) {
								value = 1.1 // Assuming 'value' is for an animation
							}
						}
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            checkLocationPermissionStatus()
                        }
                        Button(action: { // Privacy Policy Button
                                    guard let url = URL(string: "https://sites.google.com/view/lock-reminder/privacy-policy") else { return }
                                    UIApplication.shared.open(url)
                                }) {
                                    HStack{
                                        Image(systemName: "lock.fill")
                                            .foregroundStyle(.white)
                                        Text("We do not collect any data. Click to learn more")
                                            .underline()
                                            .shadow(color: .black, radius: 10)
                                            .minimumScaleFactor(0.5)
                                            .lineLimit(1)
                                            .foregroundColor(.white)
                                    }
                                }
					}
					.padding()
				}
				.tag(1)

                VStack{ // Notification Permission Page - Tag 2
                    @ObservedObject var manager = MotionManager() // Assuming a new instance or pass one
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
                    Button(action: {
                        if notificationButtonText == "Continue" {
                            withAnimation(Animation.spring().delay(0.2)) {
                                selectedPage += 1
                            }
                        } else {
                            Permission.notification.request { // Using PermissionsKit for notifications
                                DispatchQueue.main.async {
                                    if Permission.notification.authorized {
                                        notificationButtonText = "Continue"
                                    } else {
                                        notificationButtonText = "Enable"
                                        showingAlert1 = true
                                    }
                                }
                            }
                        }
                    }){
                        HStack {
                            Text(notificationButtonText)
                            if notificationButtonText == "Enable" { // Conditional icon
                                Image(systemName: "bell.badge.fill")
                            }
                        }
                    }.alert(isPresented: $showingAlert1) {
                        Alert(
                            title: Text("Please Enable Notifications"),
                            message: Text("To receive reminders, you must enable notificications."),
                            dismissButton: .default(Text("Enable in Settings"), action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            })
                        )
                    }
                    .padding([.leading, .bottom, .trailing], 20.0)
                    .frame(width: 332, height: 75)
                    .tint(.green)
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
                        if Permission.notification.authorized {
                            notificationButtonText = "Continue"
                        } else {
                            notificationButtonText = "Enable"
                        }
                        withAnimation(.easeInOut(duration: 2)) {
                            value = 1.1
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        if Permission.notification.authorized {
                            notificationButtonText = "Continue"
                        } else {
                            notificationButtonText = "Enable"
                        }
                    }
                    HStack{
                        Image(systemName: "mail.fill")
                            .foregroundStyle(.white)
                        Text("We do not send spam or promotional notifications.")
                            .underline()
                            .shadow(color: .black, radius: 10)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.white)
                    }
                }
				.padding()
				.tag(2)

				VStack{ // Setup Complete Page - Tag 3
					@ObservedObject var manager = MotionManager() // Assuming a new instance or pass one
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
                        if locationAuthStatus == .authorizedAlways && Permission.notification.authorized {
                            dontShowOnboarding = true
                        } else {
                            showingAlert2 = true
                        }
					}
                    .alert(isPresented: $showingAlert2) {
                        Alert(
                            title: Text("Please Enable All The Necessary Permissions"),
                            message: Text("To receive reminders, you must enable notificications, and you must enable \"Always\" location."),
                            dismissButton: .default(Text("Enable in Settings"), action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            })
                        )
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
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
			.edgesIgnoringSafeArea(.all)
		}
	}
	
	// MARK: - Location Permission Methods
	
	private func checkLocationPermissionStatus() {
		locationAuthStatus = locationManager.authorizationStatus
		updateLocationButtonText()
		print("Location status checked: \(locationAuthStatus)")
	}
	
	private func updateLocationButtonText() {
		if locationAuthStatus == .authorizedAlways {
			locationButtonText = "Continue"
		} else {
			locationButtonText = "Enable"
		}
	}
	
	private func handleLocationButtonTap() {
		print("Location button tapped. Current status: \(locationAuthStatus)")
		
		if locationAuthStatus == .authorizedAlways {
			// User has Always permission, proceed to next page
			withAnimation(Animation.spring().delay(0.2)) {
				selectedPage += 1
			}
		} else if locationAuthStatus == .notDetermined {
			// First time asking for permission
			requestLocationPermission()
		} else {
			// User has denied or only granted "When In Use" - show settings alert
			showingAlert = true
		}
	}
	
	private func requestLocationPermission() {
		// Use a simple delegate-based approach
		LocationPermissionDelegate.shared.requestAlwaysLocationPermission { [self] status in
			DispatchQueue.main.async {
				self.locationAuthStatus = status
				self.updateLocationButtonText()
				
				// If not Always permission after request, show alert
				if status != .authorizedAlways && status != .notDetermined {
					self.showingAlert = true
				}
			}
		}
	}
}

// MARK: - Simple Location Permission Helper

class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate {
	static let shared = LocationPermissionDelegate()
	private let locationManager = CLLocationManager()
	private var completion: ((CLAuthorizationStatus) -> Void)?
	
	override init() {
		super.init()
		locationManager.delegate = self
	}
	
	func requestAlwaysLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
		self.completion = completion
		locationManager.requestAlwaysAuthorization()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		completion?(manager.authorizationStatus)
		completion = nil // Clear completion to avoid multiple calls
	}
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

