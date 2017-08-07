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
    @NSManaged public var mails: NSSet?
    @NSManaged public var path: String
    @NSManaged public var delimiter: String
    public var flags: MCOIMAPFolderFlag{
        get {
            self.willAccessValue(forKey: "flags")
            let ms = self.primitiveValue(forKey: "flags")
            
            self.didAccessValue(forKey: "flags")
            if let num = ms{
                if case let i as Int = num{
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

extension Folder: Comparable {
    public static func <(lhs: Folder, rhs: Folder) -> Bool {
        return lhs.name < rhs.name
    }
    
    public static func ==(lhs: Folder, rhs: Folder) -> Bool {
        return lhs.name == rhs.name && lhs.path == rhs.path
    }
}