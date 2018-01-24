//
//  PersistentMail+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 04/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData


extension PersistentMail {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "PersistentMail");
    }

    @NSManaged public var body: String?
    @NSManaged public var visibleBody: String?
    @NSManaged public var decryptedBody: String?
    @NSManaged public var date: Date
    @NSManaged public var secretKey: String?
    public var flag: MCOMessageFlag{
        set {
            if newValue != flag{
                AppDelegate.getAppDelegate().mailHandler.addFlag(self.uid, flags: newValue, folder: nil)
                self.willChangeValue(forKey: "flag")
                self.setPrimitiveValue(newValue.rawValue, forKey: "flag")
                self.didChangeValue(forKey: "flag")
                
            }
            
        }
        get {
            self.willAccessValue(forKey: "flag")
            var value = MCOMessageFlag().rawValue
            if let flagInt = self.primitiveValue(forKey: "flag"){
                value = flagInt as! Int
            }
            let text = MCOMessageFlag(rawValue: value)
            self.didAccessValue(forKey: "flag")
            return text
        }

    }
    @NSManaged public var isEncrypted: Bool
    @NSManaged public var isSigned: Bool
    @NSManaged public var isCorrectlySigned: Bool
    @NSManaged public var unableToDecrypt: Bool
    @NSManaged public var subject: String?
    @NSManaged public var folder: Folder
    @NSManaged public var firstKey: PersistentKey?
    @NSManaged public var signedKey: PersistentKey?

    public var keyID: String?{
        get{
            if let key = signedKey{
                return key.keyID
            }
            return nil
        }
    }
    
    public var trouble: Bool{
        set {
            self.willChangeValue(forKey: "trouble")
            self.setPrimitiveValue(newValue, forKey: "trouble")
            self.didChangeValue(forKey: "trouble")
        }
        get {
            self.willAccessValue(forKey: "trouble")
            let text = self.primitiveValue(forKey: "trouble") as? Bool ?? true
            self.didAccessValue(forKey: "trouble")
            return text
        }
    
    }
    public var uid: UInt64{
        set {
            self.willChangeValue(forKey: "uid")
            self.setPrimitiveValue(NSDecimalNumber.init(value: newValue as UInt64), forKey: "uid")
            self.didChangeValue(forKey: "uid")
        }
        get {
            self.willAccessValue(forKey: "uid")
            let text = (self.primitiveValue(forKey: "uid") as? NSDecimalNumber)?.uint64Value
            self.didAccessValue(forKey: "uid")
            return text!
        }
    }
    
    
    public var from: MailAddress{
        set {
            if newValue is Mail_Address{
                let adr = newValue as! Mail_Address
                self.willChangeValue(forKey: "from")
                self.setValue(adr, forKey: "from" )
                self.didChangeValue(forKey: "from")
            }
        }
        get {
            self.willAccessValue(forKey: "from")
            let text = (self.primitiveValue(forKey: "from") as? Mail_Address)
            self.didAccessValue(forKey: "from")
            return text!
        }
    }
    public var containsSecretKey: Bool{
        get{
            return secretKey != nil
        }
    }
    
    private func extractPassword(body: String)-> String?{
        var pw: String? = nil
        var keyword: String? = nil
        if body.contains("PW:"){
            keyword = "PW:"
        }
        else if body.contains("pw:"){
            keyword = "pw:"
        }
        else if body.contains("password:"){
            keyword = "password:"
        }
        if let key = keyword{
            if let range = (body.range(of: key)?.upperBound){
                pw = body.substring(from: range)
                if let split = pw?.components(separatedBy: CharacterSet.whitespacesAndNewlines){
                    print(split)
                    if split.count > 0 && split[0].count > 0{
                        pw = split[0]
                    }
                    else if split.count > 1{
                        pw = split[1]
                    }
                }
            }
        }
        return pw
        
    }
    
    public func processSecretKey(pw: String?) throws -> Bool{
        if let sk = secretKey{
            let pgp = SwiftPGP()
            let keyIDs = try pgp.importKeys(key: sk, pw: pw, isSecretKey: true, autocrypt: false)
            let sks = DataHandler.handler.newSecretKeys(keyIds: keyIDs)
            return sks.count > 0
        }
        return false
    }
    
    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var to: NSSet

}

// MARK: Generated accessors for bcc
extension PersistentMail {

    @objc(addBccObject:)
    @NSManaged public func addToBcc(_ value: Mail_Address)

    @objc(removeBccObject:)
    @NSManaged public func removeFromBcc(_ value: Mail_Address)

    @objc(addBcc:)
    @NSManaged public func addToBcc(_ values: NSSet)

    @objc(removeBcc:)
    @NSManaged public func removeFromBcc(_ values: NSSet)

}

// MARK: Generated accessors for cc
extension PersistentMail {

    @objc(addCcObject:)
    @NSManaged public func addToCc(_ value: Mail_Address)

    @objc(removeCcObject:)
    @NSManaged public func removeFromCc(_ value: Mail_Address)

    @objc(addCc:)
    @NSManaged public func addToCc(_ values: NSSet)

    @objc(removeCc:)
    @NSManaged public func removeFromCc(_ values: NSSet)

}

// MARK: Generated accessors for to
extension PersistentMail {

    @objc(addToObject:)
    @NSManaged public func addToTo(_ value: Mail_Address)

    @objc(removeToObject:)
    @NSManaged public func removeFromTo(_ value: Mail_Address)

    @objc(addTo:)
    @NSManaged public func addToTo(_ values: NSSet)

    @objc(removeTo:)
    @NSManaged public func removeFromTo(_ values: NSSet)

}
