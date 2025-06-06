/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  DataController.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 5/12/23.
//

import CoreData
import Foundation

class DataController:ObservableObject {
    let container = NSPersistentContainer(name: "Model")
    
    init(){
        container.loadPersistentStores { description, error in
            if let error = error{
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    
}

