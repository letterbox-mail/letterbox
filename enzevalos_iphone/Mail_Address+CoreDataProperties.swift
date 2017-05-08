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

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Mail_Address");
    }

    @NSManaged public var address: String
    @NSManaged public var prefer_encryption: Bool
    @NSManaged public var contact: EnzevalosContact
    
    public var encryptionType: EncryptionType{
        set {
            let name = "encryptionType"
            self.willChangeValue(forKey: name)
            self.setPrimitiveValue(newValue.rawValue, forKey: name)
            self.didChangeValue(forKey: name)
        }
        get {
            
            let name = "encryptionType"
            self.willAccessValue(forKey: name)
            let string = self.primitiveValue(forKey: name) as! String?
            self.didAccessValue(forKey: name)
            return EncryptionType.fromString(string)
         }
    }
    
    
    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var from: NSSet?
    @NSManaged public var to: NSSet?

}


// MARK: Generated accessors for bcc
extension Mail_Address {
    
    @objc(addBccObject:)
    @NSManaged public func addToBcc(_ value: Mail)
    
    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(_ value: Mail)
    
    @objc(addBcc:)
    @NSManaged public func addToBcc(_ values: NSSet)
    
    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(_ values: NSSet)
    
}

// MARK: Generated accessors for cc
extension Mail_Address {
    
    @objc(addCcObject:)
    @NSManaged public func addToCc(_ value: Mail)
    
    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(_ value: Mail)
    
    @objc(addCc:)
    @NSManaged public func addToCc(_ values: NSSet)
    
    @objc(removeCc:)
    @NSManaged public func removeFromCc(_ values: NSSet)
    
}

// MARK: Generated accessors for to
extension Mail_Address {
    
    @objc(addToObject:)
    @NSManaged public func addToTo(_ value: Mail)
    
    @objc(removeToObject:)
    @NSManaged public func removeFromTo(_ value: Mail)
    
    @objc(addTo:)
    @NSManaged public func addToTo(_ values: NSSet)
    
    @objc(removeTo:)
    @NSManaged public func removeFromTo(_ values: NSSet)
    
}
