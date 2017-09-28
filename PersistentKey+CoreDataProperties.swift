//
//  PersistentKey+CoreDataProperties.swift
//  
//
//  Created by Oliver Wiese on 27.09.17.
//
//

import Foundation
import CoreData


extension PersistentKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistentKey> {
        return NSFetchRequest<PersistentKey>(entityName: "PersistentKey")
    }

    @NSManaged public var keyID: Int64
    @NSManaged public var verifiedDate: NSDate?
    @NSManaged public var encryptionType: Int16
    @NSManaged public var lastSeen: NSDate?
    @NSManaged public var lastSeenAutocrypt: NSDate?
    @NSManaged public var preferEncryption: Int16
    @NSManaged public var discoveryDate: NSDate?
    @NSManaged public var mailaddress: NSSet?
    @NSManaged public var firstMail: PersistentMail?

}

// MARK: Generated accessors for mailaddress
extension PersistentKey {

    @objc(addMailaddressObject:)
    @NSManaged public func addToMailaddress(_ value: Mail_Address)

    @objc(removeMailaddressObject:)
    @NSManaged public func removeFromMailaddress(_ value: Mail_Address)

    @objc(addMailaddress:)
    @NSManaged public func addToMailaddress(_ values: NSSet)

    @objc(removeMailaddress:)
    @NSManaged public func removeFromMailaddress(_ values: NSSet)

}
