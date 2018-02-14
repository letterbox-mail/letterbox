//
//  Record+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 14.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var key: PersistentKey?
    @NSManaged public var contact: EnzevalosContact?
    @NSManaged public var folder: Folder?
    @NSManaged public var mails: NSSet?

}

// MARK: Generated accessors for mails
extension Record {

    @objc(addMailsObject:)
    @NSManaged public func addToMails(_ value: PersistentMail)

    @objc(removeMailsObject:)
    @NSManaged public func removeFromMails(_ value: PersistentMail)

    @objc(addMails:)
    @NSManaged public func addToMails(_ values: NSSet)

    @objc(removeMails:)
    @NSManaged public func removeFromMails(_ values: NSSet)

}
