//
//  Mail+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//


import Foundation
import CoreData

@objc(PersistentMail)
open class PersistentMail: NSManagedObject, Mail {

    var showMessage: Bool = false

    var isSecure: Bool {
        return isEncrypted && isSigned && !unableToDecrypt && !trouble
    }

    var isRead: Bool {
        get {
            let value = flag.contains(MCOMessageFlag.seen)
            return value
        }
        set {
            if !newValue {
                flag.remove(MCOMessageFlag.seen)
            } else {
                flag.insert(MCOMessageFlag.seen)
            }
            _ = DataHandler.handler.save()
        }
    }

    var timeString: String {
        var returnString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        let mailTime = self.date
        let interval = Date().timeIntervalSince(mailTime as Date)
        switch interval {
        case -55..<55:
            returnString = NSLocalizedString("Now", comment: "New email")
        case 55..<120:
            returnString = NSLocalizedString("OneMinuteAgo", comment: "Email came one minute ago")
        case 120..<24 * 60 * 60:
            dateFormatter.timeStyle = .short
            returnString = dateFormatter.string(from: mailTime as Date)
        case 24 * 60 * 60..<48 * 60 * 60:
            returnString = NSLocalizedString("Yesterday", comment: "Email came yesterday")
        case 48 * 60 * 60..<72 * 60 * 60:
            returnString = NSLocalizedString("TwoDaysAgo", comment: "Email came two days ago")
        default:
            dateFormatter.dateStyle = .short
            returnString = dateFormatter.string(from: mailTime as Date)
        }
        return returnString
    }

    var shortBodyString: String? {
        guard !trouble else {
            return nil
        }
        
        var message: String? = ""
        if isEncrypted && !unableToDecrypt {
            message = decryptedBody
        } else {
            message = body
        }

        if message != nil {
            message = message!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if message!.characters.count > 50 {
                message = message!.substring(to: message!.characters.index(message!.startIndex, offsetBy: 50))
            }
            let messageArray = message!.components(separatedBy: "\n")
            return messageArray.joined(separator: " ")
        } else {
            return nil
        }
    }

    var decryptedWithOldPrivateKey: Bool = false

    func getReceivers() -> [Mail_Address] {
        var receivers = [Mail_Address] ()
        for obj in to {
            receivers.append(obj as! Mail_Address)
        }
        return receivers
    }

    func getCCs() -> [Mail_Address] {
        var receivers = [Mail_Address] ()
        for obj in cc! {
            receivers.append(obj as! Mail_Address)
        }
        return receivers
    }

    func getBCCs() -> [Mail_Address] {
        var receivers = [Mail_Address] ()
        for obj in bcc! {
            receivers.append(obj as! Mail_Address)
        }
        return receivers
    }

    //decrypt and/or check signature
    func decryptIfPossible() {
        let encType = EnzevalosEncryptionHandler.getEncryptionTypeForMail(self)
        if let encryption = EnzevalosEncryptionHandler.getEncryption(encType) {
            if encryption.isUsedForEncryption(self) == true {
                self.isEncrypted = true
                //decrypt
                encryption.decryptAndSignatureCheck(self)

            }
            if encryption.isUsedForSignature(self) == true {
                //TODO
                //check signature
                if (encryption.isCorrectlySigned(self) != nil) {
                    self.isSigned = true
                }
            }

        }
    }


    func liveDecrypt() -> String? {
        let encType = EnzevalosEncryptionHandler.getEncryptionTypeForMail(self)
        if let encryption = EnzevalosEncryptionHandler.getEncryption(encType) {
            if encryption.isUsedForEncryption(self) == true {
                self.isEncrypted = true
                //decrypt
                encryption.decryptAndSignatureCheck(self)
                return encryption.decrypt(self)
            }
            if encryption.isUsedForSignature(self) == true {
                //TODO
                //check signature
                if (encryption.isCorrectlySigned(self) != nil) {
                    self.isSigned = true
                }
            }

        }
        return nil
    }

    func getSubjectWithFlagsString() -> String {
        let subj: String
        var returnString: String = ""

        if self.subject == nil || (self.subject?.isEmpty)! {
            subj = NSLocalizedString("SubjectNo", comment: "This email has no subject")
        } else {
            subj = subject!
        }
        if self.trouble {
            returnString.append("❗️ ")
        }
        if !self.isRead {
            returnString.append("🔵 ")
        }
        if MCOMessageFlag.answered.isSubset(of: flag) {
            returnString.append("↩️ ")
        }
        if MCOMessageFlag.forwarded.isSubset(of: flag) {
            returnString.append("➡️ ")
        }
        if MCOMessageFlag.flagged.isSubset(of: flag) {
            returnString.append("⭐️ ")
        }
        return "\(returnString)\(subj)"
    }
}
