//
//  Mail_Address+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 05/01/17.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

extension Mail_Address {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Mail_Address");
    }

    @NSManaged public var address: String
    @NSManaged public var contact: EnzevalosContact?
    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var from: NSSet?
    @NSManaged public var to: NSSet?
    @NSManaged public var pseudonym: String
    @NSManaged public var primaryKeyID: String
    @NSManaged public var keys: NSSet?
    @NSManaged public var invitations: Int16



}


// MARK: Generated accessors for bcc
extension Mail_Address {

    @objc(addBccObject:)
    @NSManaged public func addToBcc(_ value: PersistentMail)

    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(_ value: PersistentMail)

    @objc(addBcc:)
    @NSManaged public func addToBcc(_ values: NSSet)

    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(_ values: NSSet)

}

// MARK: Generated accessors for cc
extension Mail_Address {

    @objc(addCcObject:)
    @NSManaged public func addToCc(_ value: PersistentMail)

    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(_ value: PersistentMail)

    @objc(addCc:)
    @NSManaged public func addToCc(_ values: NSSet)

    @objc(removeCc:)
    @NSManaged public func removeFromCc(_ values: NSSet)

}

// MARK: Generated accessors for to
extension Mail_Address {

    @objc(addToObject:)
    @NSManaged public func addToTo(_ value: PersistentMail)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(_ value: PersistentMail)

    @objc(addTo:)
    @NSManaged public func addToTo(_ values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(_ values: NSSet)

}

// MARK: Generated accessors for key
extension Mail_Address {

    @objc(addKeysObject:)
    @NSManaged public func addToKeys(_ value: PersistentKey)

    @objc(removeKeysObject:)
    @NSManaged public func removeFromKeys(_ value: PersistentKey)

    @objc(addKeys:)
    @NSManaged public func addToKeys(_ values: NSSet)

    @objc(removeKeys:)
    @NSManaged public func removeFromKeys(_ values: NSSet)

}
