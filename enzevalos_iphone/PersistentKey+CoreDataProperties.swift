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

    @NSManaged public var keyID: String
    @NSManaged public var verifiedDate: NSDate?
    @NSManaged public var lastSeen: NSDate?
    @NSManaged public var lastSeenAutocrypt: NSDate?
    @NSManaged public var discoveryDate: NSDate?
    @NSManaged public var mailaddress: NSSet?
    @NSManaged public var firstMail: PersistentMail?
    
    public var prefer_encryption: EncState{
        set {
            let name = "prefer_encryption"
            self.willChangeValue(forKey: name)
            self.setPrimitiveValue(newValue.asInt(), forKey: name)
            self.didChangeValue(forKey: name)
        }
        get {
            
            let name = "prefer_encryption"
            self.willAccessValue(forKey: name)
            let i = self.primitiveValue(forKey: name) as! Int
            self.didAccessValue(forKey: name)
            return EncState.find(i: i)
        }
    }
    
    public var encryptionType: CryptoScheme{
        set{
            let name = "encryptionType"
            self.willChangeValue(forKey: name)
            self.setPrimitiveValue(newValue.asInt(), forKey: name)
            self.didChangeValue(forKey: name)
        }
        get {
            
            let name = "encryptionType"
            self.willAccessValue(forKey: name)
            let i = self.primitiveValue(forKey: name) as! Int
            self.didAccessValue(forKey: name)
            return CryptoScheme.find(i: i)
        }
    }
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
