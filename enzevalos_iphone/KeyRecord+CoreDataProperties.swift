//
//  KeyRecord+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 14.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//
//

import Foundation
import CoreData


extension KeyRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyRecord> {
        return NSFetchRequest<KeyRecord>(entityName: "KeyRecord")
    }

    @NSManaged public var contact: EnzevalosContact
    @NSManaged public var folder: Folder
    @NSManaged public var key: PersistentKey?
    @NSManaged public var persistentMails: NSSet?

}

// MARK: Generated accessors for persitentMails
extension KeyRecord {

    @objc(addPersistentMailsObject:)
    @NSManaged public func addToPersistentMails(_ value: PersistentMail)

    @objc(removePersistentMailsObject:)
    @NSManaged public func removeFromPersistentMails(_ value: PersistentMail)

    @objc(addPersistentMails:)
    @NSManaged public func addToPersistentMails(_ values: NSSet)

    @objc(removePersistentMails:)
    @NSManaged public func removeFromPersistentMails(_ values: NSSet)

}
