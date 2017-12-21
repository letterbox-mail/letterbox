//
//  PseudonymKey+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 06.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData

extension PseudonymKey {
    
    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "PseudonymKey");
    }
    
    @NSManaged public var keyID: String
    @NSManaged public var pseudonym: String
}
