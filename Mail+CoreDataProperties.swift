//
//  Mail+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

/* 
 Fixes for next iteration:
flags -> Int (previously int16)
 new Field: unread
remove optional fields
 
 bcc/cc flied in Mail
 mail_address in EC



 
 */

extension Mail {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Mail");
    }

    @NSManaged public var body: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var flag: Int16
    @NSManaged public var isEncrypted: Bool
    @NSManaged public var isVerified: Bool
    @NSManaged public var subject: String?
    @NSManaged public var trouble: Bool
    @NSManaged public var uid: Int64
    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var from: EnzevalosContact?
    @NSManaged public var to: NSSet?

}

// MARK: Generated accessors for bcc
extension Mail {

    @objc(addBccObject:)
    @NSManaged public func addToBcc(_ value: EnzevalosContact)

    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(_ value: EnzevalosContact)

    @objc(addBcc:)
    @NSManaged public func addToBcc(_ values: NSSet)

    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(_ values: NSSet)

}

// MARK: Generated accessors for cc
extension Mail {

    @objc(addCcObject:)
    @NSManaged public func addToCc(_ value: EnzevalosContact)

    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(_ value: EnzevalosContact)

    @objc(addCc:)
    @NSManaged public func addToCc(_ values: NSSet)

    @objc(removeCc:)
    @NSManaged public func removeFromCc(_ values: NSSet)

}

// MARK: Generated accessors for to
extension Mail {

    @objc(addToObject:)
    @NSManaged public func addToTo(_ value: EnzevalosContact)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(_ value: EnzevalosContact)

    @objc(addTo:)
    @NSManaged public func addToTo(_ values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(_ values: NSSet)

}
