//
//  PseudonymMailAddress+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 03.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData

extension PseudonymMailAddress {
    
    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "PseudonymMailAddress");
    }
    
    @NSManaged public var address: String
    @NSManaged public var pseudonym: String
    
}
