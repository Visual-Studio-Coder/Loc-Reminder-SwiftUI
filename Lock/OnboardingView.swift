//
//  OnboardingView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/23/23.
//

import SwiftUI
import CoreLocation
import LocationAlwaysPermission
import NotificationPermission
import UserNotifications
import PermissionsKit

struct OnboardingView: View {
	@State var showingAlert = false
	@State var showingAlert1 = false
    @State var showingAlert2 = false
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
				VStack() {
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
				VStack {
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
                        Button(action: {
							let authorized = Permission.locationAlways.authorized
							Permission.locationAlways.request {
								locationManager.stopUpdatingLocation()
							}
							let key = Permission.locationAlways.usageDescriptionKey
                            print(key!)
							if !authorized {
								showingAlert = true
                            } else {
                                withAnimation(Animation.spring().delay(2)) { selectedPage += 1
                                }
                            }
                        }){
                            HStack{
                                Text("Enable")
                                Image(systemName: "bell.badge.fill")
                            }
                        }.alert(isPresented: $showingAlert) {
                            Alert(
                                title: Text("Always Location Permission Required"),
                                message: Text("Please enable the \"Always\" location permissions in settings so that this app can work even when it is not opened.."),
                                dismissButton: .default(Text("Enable in Settings"), action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
                        Button(action: {
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
                    Button(action: {
                        let authorized = Permission.notification.authorized
                        Permission.notification.request {
                        }
                        if !authorized {
                            showingAlert1 = true
                        } else {
                            withAnimation(Animation.spring().delay(2)) { selectedPage += 1
                            }
                        }
                    }){
                        HStack {
                            Text("Enable")
                            Image(systemName: "bell.badge.fill")
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
                        withAnimation(.easeInOut(duration: 2)) {
                            value = 1.1
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
                        if Permission.notification.authorized && Permission.locationAlways.authorized{
                            dontShowOnboarding = true
                            self
                                .opacity(1)
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
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
}
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

