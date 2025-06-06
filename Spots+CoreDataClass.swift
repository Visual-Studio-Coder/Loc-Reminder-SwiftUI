/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  Spots+CoreDataClass.swift
//
//
//  Created by Vaibhav Satishkumar on 7/24/23.
//
//

import Foundation
import CoreData
import CoreLocation

@objc(Spots)
public class Spots: NSManagedObject {
	@nonobjc public class func fetchRequest() -> NSFetchRequest<Spots> {
		return NSFetchRequest<Spots>(entityName: "Spots")
	}
	
	@NSManaged public var address: String?
	@NSManaged public var customNotificationBody: String?
	@NSManaged public var customNotificationTitle: String?
	@NSManaged public var distanceFromSpot: Int16
	@NSManaged public var id: UUID?
	@NSManaged public var latitude: Double?
	@NSManaged public var longitude: Double?
	@NSManaged public var nameOfLocation: String?
	@NSManaged public var notifyOnBoth: Bool

}
