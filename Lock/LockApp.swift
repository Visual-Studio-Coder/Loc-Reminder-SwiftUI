/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
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
    @StateObject private var dataController = DataController()
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, dataController.container.viewContext)
		}
	}
}
