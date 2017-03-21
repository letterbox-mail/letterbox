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
    
    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var from: NSSet?
    @NSManaged public var to: NSSet?

}


// MARK: Generated accessors for bcc
extension Mail_Address {
    
    @objc(addBccObject:)
    @NSManaged public func addToBcc(value: Mail)
    
    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(value: Mail)
    
    @objc(addBcc:)
    @NSManaged public func addToBcc(values: NSSet)
    
    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(values: NSSet)
    
}

// MARK: Generated accessors for cc
extension Mail_Address {
    
    @objc(addCcObject:)
    @NSManaged public func addToCc(value: Mail)
    
    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(value: Mail)
    
    @objc(addCc:)
    @NSManaged public func addToCc(values: NSSet)
    
    @objc(removeCc:)
    @NSManaged public func removeFromCc(values: NSSet)
    
}

// MARK: Generated accessors for to
extension Mail_Address {
    
    @objc(addToObject:)
    @NSManaged public func addToTo(value: Mail)
    
    @objc(removeToObject:)
    @NSManaged public func removeFromTo(value: Mail)
    
    @objc(addTo:)
    @NSManaged public func addToTo(values: NSSet)
    
    @objc(removeTo:)
    @NSManaged public func removeFromTo(values: NSSet)
    
}
