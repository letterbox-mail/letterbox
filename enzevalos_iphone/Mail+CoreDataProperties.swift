//
//  Mail+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 04/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData


extension Mail {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Mail");
    }

    @NSManaged public var body: String?
    @NSManaged public var visibleBody: String?
    @NSManaged public var decryptedBody: String?
    @NSManaged public var date: Date
    public var flag: MCOMessageFlag{
        set {
            if newValue != flag{
                AppDelegate.getAppDelegate().mailHandler.addFlag(self.uid, flags: newValue)
                self.willChangeValue(forKey: "flag")
                self.setPrimitiveValue(newValue.rawValue, forKey: "flag")
                self.didChangeValue(forKey: "flag")
                
            }
            
        }
        get {
            self.willAccessValue(forKey: "flag")
            var value = MCOMessageFlag().rawValue
            if let flagInt = self.primitiveValue(forKey: "flag"){
                value = flagInt as! Int
            }
            let text = MCOMessageFlag(rawValue: value)
            self.didAccessValue(forKey: "flag")
            return text
        }

    }
    @NSManaged public var isEncrypted: Bool
    @NSManaged public var isSigned: Bool
    @NSManaged public var isCorrectlySigned: Bool
    @NSManaged public var keyID: String
    @NSManaged public var unableToDecrypt: Bool
    @NSManaged public var subject: String?
    public var trouble: Bool{
        set {
            self.willChangeValue(forKey: "trouble")
            self.setPrimitiveValue(newValue, forKey: "trouble")
            self.didChangeValue(forKey: "trouble")
        }
        get {
            self.willAccessValue(forKey: "trouble")
            let text = self.primitiveValue(forKey: "trouble") as? Bool
            self.didAccessValue(forKey: "trouble")
            if(text == nil){
                print("NIL!!!")
            }
            return text!
        }
    
    }
    public var uid: UInt64{
    
        set {
            self.willChangeValue(forKey: "uid")
            self.setPrimitiveValue(NSDecimalNumber.init(value: newValue as UInt64), forKey: "uid")
            self.didChangeValue(forKey: "uid")
        }
        get {
            self.willAccessValue(forKey: "uid")
            let text = (self.primitiveValue(forKey: "uid") as? NSDecimalNumber)?.uint64Value
            self.didAccessValue(forKey: "uid")
            return text!
        }
    }
    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var from: Mail_Address
    @NSManaged public var to: NSSet

}

// MARK: Generated accessors for bcc
extension Mail {

    @objc(addBccObject:)
    @NSManaged public func addToBcc(_ value: Mail_Address)

    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(_ value: Mail_Address)

    @objc(addBcc:)
    @NSManaged public func addToBcc(_ values: NSSet)

    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(_ values: NSSet)

}

// MARK: Generated accessors for cc
extension Mail {

    @objc(addCcObject:)
    @NSManaged public func addToCc(_ value: Mail_Address)

    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(_ value: Mail_Address)

    @objc(addCc:)
    @NSManaged public func addToCc(_ values: NSSet)

    @objc(removeCc:)
    @NSManaged public func removeFromCc(_ values: NSSet)

}

// MARK: Generated accessors for to
extension Mail {

    @objc(addToObject:)
    @NSManaged public func addToTo(_ value: Mail_Address)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(_ value: Mail_Address)

    @objc(addTo:)
    @NSManaged public func addToTo(_ values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(_ values: NSSet)

}
