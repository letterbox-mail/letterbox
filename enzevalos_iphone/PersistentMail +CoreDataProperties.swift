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
    @NSManaged public var record: KeyRecord?

    public var flag: MCOMessageFlag {
        set {
            if newValue != flag {
                AppDelegate.getAppDelegate().mailHandler.addFlag(self.uid, flags: newValue, folder: folder.name)
                self.willChangeValue(forKey: "flag")
                self.setPrimitiveValue(newValue.rawValue, forKey: "flag")
                self.didChangeValue(forKey: "flag")

            }

        }
        get {
            self.willAccessValue(forKey: "flag")
            var value = MCOMessageFlag().rawValue
            if let flagInt = self.primitiveValue(forKey: "flag") {
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
    @NSManaged public var received: Bool

    @NSManaged public var gmailMessageID: NSNumber?
    @NSManaged public var gmailThreadID: NSNumber?
    @NSManaged public var messageID: String?
    @NSManaged public var notLoadedMessages: String?

    @NSManaged public var xMailer: String?


    public var keyID: String? {
        set {
            self.willChangeValue(forKey: "keyID")
            self.setPrimitiveValue(newValue, forKey: "keyID")
            self.didChangeValue(forKey: "keyID")
        }
        get {
            var signKeyID: String?
            if let k = self.signedKey {
                signKeyID = k.keyID
            }
            self.willAccessValue(forKey: "keyID")
            if let text = self.primitiveValue(forKey: "keyID") {
                signKeyID = text as? String
            }
            else {
                if let id = signKeyID {
                    self.setPrimitiveValue(id, forKey: "keyID")
                }
            }
            self.didAccessValue(forKey: "keyID")
            return signKeyID
        }
    }


    public var trouble: Bool {
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
    public var uid: UInt64 {
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
            return text
        }
    }
    public var from: MailAddress {
        set {
            if newValue is Mail_Address {
                let adr = newValue as! Mail_Address
                self.willChangeValue(forKey: "from")
                self.setValue(adr, forKey: "from")
                self.didChangeValue(forKey: "from")
            }
        }
        get {
            self.willAccessValue(forKey: "from")
            let text = (self.primitiveValue(forKey: "from") as? Mail_Address)
            self.didAccessValue(forKey: "from")
            if let text = text {
                return text
            }
            return Mail_Address()
        }
    }
    public var containsSecretKey: Bool {
        get {
            return secretKey != nil
        }
    }

    private func extractPassword(body: String) -> String? {
        var pw: String? = nil
        var keyword: String? = nil
        if body.contains("PW:") {
            keyword = "PW:"
        }
        else if body.contains("pw:") {
            keyword = "pw:"
        }
        else if body.contains("password:") {
            keyword = "password:"
        }
        if let key = keyword {
            if let range = (body.range(of: key)?.upperBound) {
                pw = String(body[range...])
                if let split = pw?.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                    if split.count > 0 && split[0].count > 0 {
                        pw = split[0]
                    }
                    else if split.count > 1 {
                        pw = split[1]
                    }
                }
            }
        }
        return pw

    }

    public func processSecretKey(pw: String?) throws -> Bool {
        if let sk = secretKey {
            let pgp = SwiftPGP()
            let keyIDs = try pgp.importKeys(key: sk, pw: pw, isSecretKey: true, autocrypt: false)
            let sks = DataHandler.handler.newSecretKeys(keyIds: keyIDs, addPKs: true)
            return sks.count > 0
        }
        return false
    }

    @NSManaged public var bcc: NSSet?
    @NSManaged public var cc: NSSet?
    @NSManaged public var to: NSSet
    @NSManaged public var attachments: NSSet?
    @NSManaged public var referenceMails: NSSet?

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

// MARK: Generated accessors for attachments
extension PersistentMail {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}

// MARK: Generated accessors for attachments
extension PersistentMail {

    @objc(addReferenceMailsObject:)
    @NSManaged public func addToReferenceMails(_ value: PersistentMail)

    @objc(removeReferenceMailsObject:)
    @NSManaged public func removeFromReferenceMails(_ value: PersistentMail)

    @objc(addReferenceMails:)
    @NSManaged public func addToReferenceMails(_ values: NSSet)

    @objc(removeReferenceMails:)
    @NSManaged public func removeFromReferenceMails(_ values: NSSet)

}
