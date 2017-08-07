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

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "State");
    }

    public var currentMails: Int{
        set {
            let name = "currentMails"
            self.willChangeValue(forKey: name)
            self.setPrimitiveValue(newValue, forKey: name)
            self.didChangeValue(forKey: name)
        }
        get {
            let name = "currentMails"
            self.willAccessValue(forKey: name)
            let result = Int(self.primitiveValue(forKey: name) as! Int64)
            self.didAccessValue(forKey: name)
            return result
        }
    }
    
    public var currentContacts: Int{
        set {
            let name = "currentContacts"
            self.willChangeValue(forKey: name)
            self.setPrimitiveValue(newValue, forKey: name)
            self.didChangeValue(forKey: name)
        }
        get {
            let name = "currentContacts"
            self.willAccessValue(forKey: name)
            let result = Int(self.primitiveValue(forKey: name) as! Int64)
            self.didAccessValue(forKey: name)
            return result
        }
    }
}
