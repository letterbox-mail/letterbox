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

    @NSManaged public var name: String?
    @NSManaged public var mails: NSSet?
    @NSManaged public var parent: Folder?
    @NSManaged public var subfolder: NSSet?
    public var lastID: UInt64{
        
        set {
            self.willChangeValue(forKey: "lastID")
            self.setPrimitiveValue(NSDecimalNumber.init(value: newValue as UInt64), forKey: "lastID")
            self.didChangeValue(forKey: "lastID")
        }
        get {
            self.willAccessValue(forKey: "lastID")
            let text = (self.primitiveValue(forKey: "lastID") as? NSDecimalNumber)?.uint64Value
            self.didAccessValue(forKey: "lastID")
            if text == nil{
                return 1
            }
            return text!
        }
    }
    
    public var maxID: UInt64{
        
        set {
            self.willChangeValue(forKey: "maxID")
            self.setPrimitiveValue(NSDecimalNumber.init(value: newValue as UInt64), forKey: "maxID")
            self.didChangeValue(forKey: "maxID")
        }
        get {
            self.willAccessValue(forKey: "maxID")
            let text = (self.primitiveValue(forKey: "maxID") as? NSDecimalNumber)?.uint64Value
            self.didAccessValue(forKey: "maxID")
            if text == nil{
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

    @objc(addMails:)
    @NSManaged public func addToMails(_ values: NSSet)

    @objc(removeMails:)
    @NSManaged public func removeFromMails(_ values: NSSet)

}

// MARK: Generated accessors for subfolder
extension Folder {

    @objc(addSubfolderObject:)
    @NSManaged public func addToSubfolder(_ value: Folder)

    @objc(removeSubfolderObject:)
    @NSManaged public func removeFromSubfolder(_ value: Folder)

    @objc(addSubfolder:)
    @NSManaged public func addToSubfolder(_ values: NSSet)

    @objc(removeSubfolder:)
    @NSManaged public func removeFromSubfolder(_ values: NSSet)

}
