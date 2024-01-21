//
//  LockApp.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 4/25/23.
//

import SwiftUI
import CoreData

@main
struct LockApp: App {
	@AppStorage("shouldShowOnboarding") public var dontShowOnboarding : Bool = false
    
    @StateObject private var dataController = DataController()
	
	
	
	
	var body: some Scene {
		WindowGroup {
			
			if dontShowOnboarding{
				ContentView()
					.environment(\.managedObjectContext, dataController.container.viewContext)
					.onAppear(){
						withAnimation(Animation
									  
							.easeInOut(duration: 3)) {
								dontShowOnboarding = true
							}
						
					}
					.opacity(dontShowOnboarding ? 1 : 0)
				
			} else {
				OnboardingView()
			}
		}
	}
}
