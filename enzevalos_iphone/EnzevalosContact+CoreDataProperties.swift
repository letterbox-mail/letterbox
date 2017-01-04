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
    @NSManaged public var key: String?
    @NSManaged public var mail_address: String?
    @NSManaged public var prefer_encryption: Bool
    @NSManaged public var cncontact: String?
    @NSManaged public var from: NSSet?
    @NSManaged public var to: NSSet?
    @NSManaged public var cc: Mail?
    @NSManaged public var bcc: Mail?

}

// MARK: Generated accessors for from
extension EnzevalosContact {

    @objc(addFromObject:)
    @NSManaged public func addToFrom(_ value: Mail)

    @objc(removeFromObject:)
    @NSManaged public func removeFromFrom(_ value: Mail)

    @objc(addFrom:)
    @NSManaged public func addToFrom(_ values: NSSet)

    @objc(removeFrom:)
    @NSManaged public func removeFromFrom(_ values: NSSet)

}

// MARK: Generated accessors for to
extension EnzevalosContact {

    @objc(addToObject:)
    @NSManaged public func addToTo(_ value: Mail)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(_ value: Mail)

    @objc(addTo:)
    @NSManaged public func addToTo(_ values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(_ values: NSSet)

}
