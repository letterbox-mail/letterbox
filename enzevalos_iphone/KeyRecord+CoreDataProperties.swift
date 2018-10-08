//
//  KeyRecord+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 14.02.18.
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
