//
//  Folder+CoreDataProperties.swift
//
//
//  Created by Oliver Wiese on 05.07.17.
//
//

import Foundation
import CoreData


extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var parent: Folder?
    @NSManaged public var subfolder: NSSet?
    @NSManaged public var mails: NSSet?
    @NSManaged public var keyRecords: NSSet?
    @NSManaged public var path: String //backendFolderPath
    @NSManaged public var lastUpdate: Date?
    @NSManaged public var pseudonym: String
    @NSManaged public var icon: String

    public var uidvalidity: UInt32? {
        set {
            if let num = newValue {
                self.willChangeValue(forKey: "uidvalidity")
                self.setPrimitiveValue(NSDecimalNumber.init(value: num as UInt32), forKey: "uidvalidity")
                self.didChangeValue(forKey: "uidvalidity")
            }
        }
        get {
            self.willAccessValue(forKey: "uidvalidity")
            let text = (self.primitiveValue(forKey: "uidvalidity") as? NSDecimalNumber)?.uint32Value
            self.didAccessValue(forKey: "uidvalidity")
            if let num = text {
                return num
            }
            return nil
        }
    }


    @NSManaged public var delimiter: String
    public var flags: MCOIMAPFolderFlag {
        get {
            self.willAccessValue(forKey: "flags")
            let ms = self.primitiveValue(forKey: "flags")

            self.didAccessValue(forKey: "flags")
            if let num = ms {
                if case let i as Int = num {
                    return MCOIMAPFolderFlag.init(rawValue: i)
                }
            }
            return MCOIMAPFolderFlag.unmarked
        }
        set {
            self.willChangeValue(forKey: "flags")
            self.setPrimitiveValue(Int16(newValue.rawValue), forKey: "flags")
            self.didChangeValue(forKey: "flags")
        }
    }

    public var maxID: UInt64 {

        set {
            self.willChangeValue(forKey: "maxID")
            self.setPrimitiveValue(NSDecimalNumber.init(value: newValue as UInt64), forKey: "maxID")
            self.didChangeValue(forKey: "maxID")
        }
        get {
            self.willAccessValue(forKey: "maxID")
            let text = (self.primitiveValue(forKey: "maxID") as? NSDecimalNumber)?.uint64Value
            self.didAccessValue(forKey: "maxID")
            if text == nil {
                return 1
            }
            return text!
        }
    }
}

// MARK: Generated accessors for mails
extension Folder {

    @objc(addMailsObject:)
    @NSManaged public func addToMails(_ value: PersistentMail)

    @objc(removeMailsObject:)
    @NSManaged public func removeFromMails(_ value: PersistentMail)

    @objc(addSubfolderObject:)
    @NSManaged public func addToSubfolder(_ value: Folder)

    @objc(removeSubfolderObject:)
    @NSManaged public func removeFromSubfolder(_ value: Folder)

    @objc(addKeyRecordsObject:)
    @NSManaged public func addToKeyRecords(_ value: KeyRecord)

    @objc(removeKeyRecordsObject:)
    @NSManaged public func removeFromKeyRecords(_ value: KeyRecord)

    @objc(addMails:)
    @NSManaged public func addToMails(_ values: NSSet)

    @objc(removeMails:)
    @NSManaged public func removeFromMails(_ values: NSSet)

    @objc(addSubfolder:)
    @NSManaged public func addToSubfolder(_ values: NSSet)

    @objc(removeSubfolder:)
    @NSManaged public func removeFromSubfolder(_ values: NSSet)

    @objc(addKeyRecords:)
    @NSManaged public func addToKeyRecords(_ values: NSSet)

    @objc(removeKeyRecords:)
    @NSManaged public func removeFromKeyRecords(_ values: NSSet)

}

extension Folder: Comparable {
    public static func < (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.name < rhs.name
    }

    public static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.name == rhs.name && lhs.path == rhs.path
    }
}
