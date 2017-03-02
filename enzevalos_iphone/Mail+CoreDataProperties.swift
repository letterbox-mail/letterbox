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

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Mail");
    }

    @NSManaged public var body: String?
    @NSManaged public var visibleBody: String?
    @NSManaged public var decryptedBody: String?
    @NSManaged public var date: NSDate
    public var flag: MCOMessageFlag{
        set {
            if newValue != flag{
                AppDelegate.getAppDelegate().mailHandler.addFlag(self.uid, flags: newValue)
                self.willChangeValueForKey("flag")
                self.setPrimitiveValue(newValue.rawValue, forKey: "flag")
                self.didChangeValueForKey("flag")
            }
            
        }
        get {
            self.willAccessValueForKey("flag")
            let text = MCOMessageFlag(rawValue: (self.primitiveValueForKey("flag") as? Int)!)
            self.didAccessValueForKey("flag")
            return text
        }

    }
    @NSManaged public var isEncrypted: Bool
    @NSManaged public var isSigned: Bool
    @NSManaged public var isCorrectlySigned: Bool
    @NSManaged public var unableToDecrypt: Bool
    @NSManaged public var subject: String?
    public var trouble: Bool{
        set {
            self.willChangeValueForKey("trouble")
            self.setPrimitiveValue(newValue, forKey: "trouble")
            self.didChangeValueForKey("trouble")
        }
        get {
            self.willAccessValueForKey("trouble")
            let text = self.primitiveValueForKey("trouble") as? Bool
            self.didAccessValueForKey("trouble")
            return text!
        }
    
    }
    public var uid: UInt64{
    
        set {
            self.willChangeValueForKey("uid")
            self.setPrimitiveValue(NSDecimalNumber.init(unsignedLongLong: newValue), forKey: "uid")
            self.didChangeValueForKey("uid")
        }
        get {
            self.willAccessValueForKey("uid")
            let text = (self.primitiveValueForKey("uid") as? NSDecimalNumber)?.unsignedLongLongValue
            self.didAccessValueForKey("uid")
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
    @NSManaged public func addToBcc(value: Mail_Address)

    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(value: Mail_Address)

    @objc(addBcc:)
    @NSManaged public func addToBcc(values: NSSet)

    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(values: NSSet)

}

// MARK: Generated accessors for cc
extension Mail {

    @objc(addCcObject:)
    @NSManaged public func addToCc(value: Mail_Address)

    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(value: Mail_Address)

    @objc(addCc:)
    @NSManaged public func addToCc(values: NSSet)

    @objc(removeCc:)
    @NSManaged public func removeFromCc(values: NSSet)

}

// MARK: Generated accessors for to
extension Mail {

    @objc(addToObject:)
    @NSManaged public func addToTo(value: Mail_Address)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(value: Mail_Address)

    @objc(addTo:)
    @NSManaged public func addToTo(values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(values: NSSet)

}
