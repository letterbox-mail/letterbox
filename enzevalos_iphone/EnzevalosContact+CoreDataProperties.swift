//
//  EnzevalosContact+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 04/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData


extension EnzevalosContact {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "EnzevalosContact");
    }

    @NSManaged public var displayname: String?
    @NSManaged public var cnidentifier: String?
    @NSManaged public var addresses: NSSet?

}


// MARK: Generated accessors for addresses
extension EnzevalosContact {
    
    @objc(addAddressesObject:)
    @NSManaged public func addToAddresses(_ value: Mail_Address)
    
    @objc(removeAddressesObject:)
    @NSManaged public func removeFromAddresses(_ value: Mail_Address)
    
    @objc(addAddresses:)
    @NSManaged public func addToAddresses(_ values: NSSet)
    
    @objc(removeAddresses:)
    @NSManaged public func removeFromAddresses(_ values: NSSet)
    
}


