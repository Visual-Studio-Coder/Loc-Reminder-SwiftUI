/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  OnboardingView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/23/23.
//

import SwiftUI
import CoreLocation
import UserNotifications
import PermissionsKit

struct OnboardingView: View {
    @Binding var isPresented: Bool // This remains the same
    
    @State private var currentPage = 0
    @State private var animationScale = 1.0
    @State private var isButtonDisabled = false
    @EnvironmentObject var locationManager: LocationDataManager // USE THIS
    
    // Permission states
    @State private var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    // Alert states
    @State private var showLocationAlert = false
    @State private var showNotificationAlert = false
    @State private var showFinalAlert = false
    
    let coolView = AuroraView()
    
    var body: some View {
        ZStack {
            coolView
            
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                locationPage.tag(1)
                notificationPage.tag(2)
                completePage.tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .onAppear {
                checkPermissionStatuses()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkPermissionStatuses()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack {
            VStack {
                ParallaxView()
                    .scaledToFit()
                    .scaleEffect(animationScale)
                    .frame(width: 400, height: 400)
                
                Text("Loc Reminder")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(10)
                
                Text("Never forget to lock your home ever again!")
                    .frame(width: 332, height: 75)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                Button("Continue") {
                    navigateToPage(1)
                }
                .disabled(isButtonDisabled)
                .buttonStyle(customButtonStyle)
                .frame(height: 50) // Fixed height for button
                .onAppear {
                    withAnimation(.easeInOut(duration: 2)) {
                        animationScale = 1.1
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Location Permission Page
    private var locationPage: some View {
        VStack {
            VStack {
                Image("location")
                    .resizable()
                    .cornerRadius(30)
                    .shadow(color: Color(hue: 1.0, saturation: 0.303, brightness: 0.549), radius: 22)
                    .scaledToFit()
                    .padding(40)
                    .frame(width: 400, height: 400)
                
                Text("Enable Location")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(10)
                
                Text("Enable \"Always\" location access for notifications when you leave home, even when the app is closed.")
                    .frame(width: 332, height: 75)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: handleLocationButton) {
                    HStack {
                        Text(locationButtonText)
                        if locationPermissionStatus != .authorizedAlways {
                            Image(systemName: "location.fill")
                        }
                    }
                }
                .disabled(isButtonDisabled)
                .buttonStyle(customButtonStyle)
                .frame(height: 50) // Fixed height for button
                .alert("Location Permission Required", isPresented: $showLocationAlert) {
                    Button("Open Settings") {
                        openAppSettings()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Please enable \"Always\" location permissions in Settings for this app to work properly.")
                }
                
                privacyPolicyButton
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                animationScale = 1.1
            }
        }
    }
    
    // MARK: - Notification Permission Page
    private var notificationPage: some View {
        VStack {
            Image("notification")
                .resizable()
                .cornerRadius(30)
                .shadow(color: .gray, radius: 22)
                .scaledToFit()
                .padding(40)
                .frame(width: 400, height: 400)
            
            Text("Enable Notifications")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(10)
            
            Text("Loc Reminder alerts you by delivering notifications when location-based events occur.")
                .frame(width: 332, height: 75)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: handleNotificationButton) {
                HStack {
                    Text(notificationButtonText)
                    if notificationPermissionStatus != .authorized {
                        Image(systemName: "bell.badge.fill")
                    }
                }
            }
            .disabled(isButtonDisabled)
            .buttonStyle(customButtonStyle)
            .frame(height: 50) // Fixed height for button
            .alert("Notification Permission Required", isPresented: $showNotificationAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive location reminders.")
            }
            
            HStack {
                Image(systemName: "mail.fill")
                    .foregroundColor(.white)
                Text("Loc Reminder does not send spam or promotional notifications.")
                    .underline()
                    .shadow(color: .black, radius: 10)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                animationScale = 1.1
            }
        }
    }
    
    // MARK: - Setup Complete Page
    private var completePage: some View {
        VStack {
            Image("LockReminderHappyFace")
                .resizable()
                .foregroundColor(.white)
                .shadow(color: .white, radius: 10)
                .cornerRadius(30)
                .shadow(color: .gray, radius: 1)
                .scaledToFit()
                .padding(40)
                .frame(width: 400, height: 400)
            
            Text("Setup Complete")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(10)
            
            Text("You are ready to get started. Click dismiss and head to the \"Spots\" tab to add your first spot!")
                .frame(width: 332, height: 75)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            Button("Dismiss") {
                handleDismiss()
            }
            .disabled(isButtonDisabled)
            .buttonStyle(customButtonStyle)
            .frame(height: 50) // Fixed height for button
            .alert("Permissions Required", isPresented: $showFinalAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Skip Setup", role: .destructive) {
                    print("🔄 Skip Setup: About to set isPresented to false")
                    self.isPresented = false // Use the binding
                    print("📊 Skip Setup: New isPresented: \(self.isPresented)")
                }
            } message: {
                Text("For the best experience, please enable both location (Always) and notification permissions.")
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                animationScale = 1.1
            }
        }
    }
    
    // MARK: - Reusable Components
    private var privacyPolicyButton: some View {
        Button(action: openPrivacyPolicy) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                Text("Loc Reminder does not collect any data. Click to learn more")
                    .underline()
                    .shadow(color: .black, radius: 10)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var customButtonStyle: some ButtonStyle {
        threeDimensionalButton(
            lateralGradient: LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .init(red: 0.3, green: 0.5, blue: 0.9), location: 0.00001),
                    .init(color: .init(red: 0.484, green: 0.7, blue: 1), location: 0.1),
                    .init(color: .init(red: 0.484, green: 0.7, blue: 1), location: 0.9),
                    .init(color: .init(red: 0.3, green: 0.5, blue: 0.9), location: 0.99999)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            flatGradient: LinearGradient(
                gradient: Gradient(colors: [.white, .init(red: 0.584, green: 0.749, blue: 1)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Computed Properties
    private var locationButtonText: String {
        return locationPermissionStatus == .authorizedAlways ? "Continue" : "Enable"
    }
    
    private var notificationButtonText: String {
        return notificationPermissionStatus == .authorized ? "Continue" : "Enable"
    }
    
    // MARK: - Action Methods
    private func navigateToPage(_ page: Int) {
        guard !isButtonDisabled else { return }
        
        isButtonDisabled = true
        
        // Standardized delay to allow button animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.currentPage = page
            }
            
            // Re-enable button after page transition animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3s is duration of page animation
                self.isButtonDisabled = false
            }
        }
    }
    
    private func handleLocationButton() {
        guard !isButtonDisabled else { return }
        
        if locationPermissionStatus == .authorizedAlways {
            navigateToPage(2)
        } else {
            isButtonDisabled = true
            // Standardized delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.requestLocationPermission()
            }
        }
    }
    
    private func handleNotificationButton() {
        guard !isButtonDisabled else { return }
        
        if notificationPermissionStatus == .authorized {
            navigateToPage(3)
        } else {
            isButtonDisabled = true
            // Standardized delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.requestNotificationPermission()
            }
        }
    }
    
    private func handleDismiss() {
        guard !isButtonDisabled else { return }
        
        isButtonDisabled = true
        
        // Standardized delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.locationPermissionStatus == .authorizedAlways && self.notificationPermissionStatus == .authorized {
                print("🔄 About to set isPresented to false (permissions GRANTED)")
                print("📊 Current isPresented (via binding): \(self.isPresented)")
                self.isPresented = false // This will now dismiss the fullScreenCover
                print("📊 New isPresented (via binding): \(self.isPresented)")
                print("✅ Onboarding dismissed - permissions granted")
                // isButtonDisabled remains true as the view should disappear.
            } else {
                print("⚠️ Missing permissions (handleDismiss):")
                print("   Location: \(self.locationPermissionStatus.rawValue)")
                print("   Notification: \(self.notificationPermissionStatus.rawValue)")
                self.showFinalAlert = true
                self.isButtonDisabled = false 
                print("⚠️ Showing final alert - missing permissions")
            }
        }
    }
    
    // MARK: - Permission Methods
    private func checkPermissionStatuses() {
        locationPermissionStatus = locationManager.locationManager.authorizationStatus
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestLocationPermission() {
        switch locationPermissionStatus {
        case .notDetermined:
            locationManager.locationManager.requestWhenInUseAuthorization() // Uses environment object
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkLocationAfterRequest()
            }
            
        case .authorizedWhenInUse:
            locationManager.locationManager.requestAlwaysAuthorization() // Uses environment object
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkLocationAfterRequest()
            }
            
        case .denied, .restricted:
            showLocationAlert = true
            isButtonDisabled = false
            
        case .authorizedAlways:
            navigateToPage(2)
            
        @unknown default:
            showLocationAlert = true
            isButtonDisabled = false
        }
    }
    
    private func checkLocationAfterRequest() {
        checkPermissionStatuses()
        
        if locationPermissionStatus == .authorizedAlways {
            navigateToPage(2)
        } else if locationPermissionStatus == .authorizedWhenInUse {
            locationManager.locationManager.requestAlwaysAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkPermissionStatuses()
                if self.locationPermissionStatus != .authorizedAlways {
                    self.showLocationAlert = true
                }
                self.isButtonDisabled = false
            }
        } else {
            showLocationAlert = true
            isButtonDisabled = false
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationPermissionStatus = .authorized
                    self.navigateToPage(3)
                } else {
                    self.showNotificationAlert = true
                    self.isButtonDisabled = false
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://github.com/Visual-Studio-Coder/Loc-Reminder-SwiftUI/blob/master/PRIVACY.md") else { return }
        UIApplication.shared.open(url)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a dummy binding for preview
        OnboardingView(isPresented: .constant(true))
    }
}

