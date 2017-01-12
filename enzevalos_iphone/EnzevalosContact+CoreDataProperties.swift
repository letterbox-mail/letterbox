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

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "EnzevalosContact");
    }

    @NSManaged public var displayname: String?
    @NSManaged public var cnidentifier: String?
    @NSManaged public var from: NSSet?
    @NSManaged public var to: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var bcc: NSSet?
    @NSManaged public var addresses: NSSet?

}

// MARK: Generated accessors for from
extension EnzevalosContact {

    @objc(addFromObject:)
    @NSManaged public func addToFrom(value: Mail)

    @objc(removeFromObject:)
    @NSManaged public func removeFromFrom(value: Mail)

    @objc(addFrom:)
    @NSManaged public func addToFrom(values: NSSet)

    @objc(removeFrom:)
    @NSManaged public func removeFromFrom(values: NSSet)

}

// MARK: Generated accessors for to
extension EnzevalosContact {

    @objc(addToObject:)
    @NSManaged public func addToTo(value: Mail)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(value: Mail)

    @objc(addTo:)
    @NSManaged public func addToTo(values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(values: NSSet)

}

// MARK: Generated accessors for cc
extension EnzevalosContact {
    
    @objc(addCCObject:)
    @NSManaged public func addToCC(value: Mail)
    
    @objc(removeCCObject:)
    @NSManaged public func removeFromCC(value: Mail)
    
    @objc(addCC:)
    @NSManaged public func addToCC(values: NSSet)
    
    @objc(removeCC:)
    @NSManaged public func removeFromCC(values: NSSet)
    
}

// MARK: Generated accessors for bcc
extension EnzevalosContact {
    
    @objc(addBCCObject:)
    @NSManaged public func addToBCC(value: Mail)
    
    @objc(removeBCCObject:)
    @NSManaged public func removeFromBCC(value: Mail)
    
    @objc(addBCC:)
    @NSManaged public func addToBCC(values: NSSet)
    
    @objc(removeBCC:)
    @NSManaged public func removeFromBCC(values: NSSet)
    
}

// MARK: Generated accessors for addresses
extension EnzevalosContact {
    
    @objc(addAddressesObject:)
    @NSManaged public func addToAddresses(value: Mail_Address)
    
    @objc(removeAddressesObject:)
    @NSManaged public func removeFromAddresses(value: Mail_Address)
    
    @objc(addAddresses:)
    @NSManaged public func addToAddresses(values: NSSet)
    
    @objc(removeAddresses:)
    @NSManaged public func removeFromAddresses(values: NSSet)
    
}


