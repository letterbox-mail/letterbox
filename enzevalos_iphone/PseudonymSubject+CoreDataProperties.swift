//
//  PseudonymSubject+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 06.12.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData

extension PseudonymSubject {
    
    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "PseudonymSubject");
    }
    
    @NSManaged public var subject: String
    @NSManaged public var pseudonym: String
}
