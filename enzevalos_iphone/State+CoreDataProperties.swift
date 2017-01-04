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

    @nonobjc public class func fetchRequest() -> NSFetchRequest<State> {
        return NSFetchRequest<State>(entityName: "State");
    }

    @NSManaged public var currentMails: Int64
    @NSManaged public var currentContacts: Int64
    @NSManaged public var maxUID: Int64

}
