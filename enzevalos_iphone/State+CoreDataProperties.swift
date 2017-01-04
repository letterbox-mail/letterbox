//
//  State+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 04/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData


extension State {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "State");
    }

    @NSManaged public var currentMails: Int64
    @NSManaged public var currentContacts: Int64
    @NSManaged public var maxUID: NSDecimalNumber

}
