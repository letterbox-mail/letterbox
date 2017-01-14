//
//  State+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 04/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData


extension State {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "State");
    }

    public var currentMails: Int{
        set {
            let name = "currentMails"
            self.willChangeValueForKey(name)
            self.setPrimitiveValue(newValue, forKey: name)
            self.didChangeValueForKey(name)
        }
        get {
            let name = "currentMails"
            self.willAccessValueForKey(name)
            let result = Int(self.primitiveValueForKey(name) as! Int64)
            self.didAccessValueForKey(name)
            return result
        }
    }
    
    public var currentContacts: Int{
        set {
            let name = "currentContacts"
            self.willChangeValueForKey(name)
            self.setPrimitiveValue(newValue, forKey: name)
            self.didChangeValueForKey(name)
        }
        get {
            let name = "currentContacts"
            self.willAccessValueForKey(name)
            let result = Int(self.primitiveValueForKey(name) as! Int64)
            self.didAccessValueForKey(name)
            return result
        }
    }
    
    public var maxUID: UInt64{
        set {
            let name = "maxUID"
            self.willChangeValueForKey(name)
            self.setPrimitiveValue(NSDecimalNumber(unsignedLongLong: newValue), forKey: name)
            self.didChangeValueForKey(name)
        }
        get {
            let name = "maxUID"
            self.willAccessValueForKey(name)
            let result = (self.primitiveValueForKey(name) as! NSDecimalNumber).unsignedLongLongValue
            self.didAccessValueForKey(name)
            return result
        }

    }

}
