//
//  Mail_Address+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 05/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Mail_Address {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Mail_Address");
    }

    @NSManaged public var address: String
    @NSManaged public var prefer_encryption: Bool
    @NSManaged public var contact: EnzevalosContact

}
