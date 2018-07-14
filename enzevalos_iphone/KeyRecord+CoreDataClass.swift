//
//  KeyRecord+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 14.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//
//

import Foundation
import CoreData
import Contacts
import UIKit

@objc(KeyRecord)
public class KeyRecord: NSManagedObject, Record {


    public var name: String {
        get {
            return self.ezContact.name
        }
    }

    public var hasKey: Bool {
        get {
            return key != nil
        }
    }

    public var isSecure: Bool {
        get {
            return hasKey
        }
    }

    public var isVerified: Bool {
        get {
            if let k = key {
                return k.isVerified()
            }
            return false
        }
    }

    public var keyID: String? {
        if let k = key {
            return k.keyID
        }
        return nil
    }

    public var cryptoscheme: CryptoScheme {
        get {
            if let k = key {
                return k.encryptionType
            }
            return CryptoScheme.UNKNOWN
        }
    }

    public var fingerprint: String? {
        get {
            if let k = pgpKey {
                if let pk = k.publicKey {
                    return pk.fingerprint.description()
                }
                else if let sk = k.secretKey {
                    return sk.fingerprint.description()
                }
                return k.keyID.longIdentifier
            }
            return nil
        }
    }

    private var pgpKey: Key? {
        get {
            if let id = key?.keyID {
                let pgp = SwiftPGP()
                return pgp.loadKey(id: id)
            }
            return nil
        }
    }

    public var ezContact: EnzevalosContact {
        get {
            return contact
        }
    }

    public var mails: [PersistentMail] {
        get {
            if let m = persistentMails as? Set<PersistentMail> {
                return Array(m).sorted()
            }
            return []
        }
    }

    public var cnContact: CNContact? {
        get {
            return contact.cnContact
        }
    }

    public var color: UIColor {
        get {
            return contact.getColor()
        }
    }

    public var image: UIImage {
        get {
            return contact.getImageOrDefault()

        }
    }

    public var addresses: [MailAddress] {
        get {
            if let k = key {
                if let addrs = k.mailaddress as? Set<Mail_Address> {
                    return Array(addrs)
                }
                return []
            }
            if let addrs = contact.addresses as? Set<Mail_Address> {
                return Array(addrs)
            }
            return []
        }
    }

    var addressNames: [String] {
        get {
            let adrs = addresses
            var names = [String]()
            for adr in adrs {
                names.append(adr.mailAddress)
            }
            return names
        }
    }

    public func verify() {
        if let k = key {
            k.verify()
        }
    }

    public func match(mail: PersistentMail) -> Bool {
        if mail.folder == folder {
            if let recordFingerprint = fingerprint, let signedKey = mail.signedKey {
                let pgp = SwiftPGP()
                if let key = pgp.loadKey(id: signedKey.keyID)?.publicKey {
                    return key.fingerprint.description() == recordFingerprint
                }
                return false
            }
            if !hasKey && !mail.isSigned {
                for addr in addresses {
                    if mail.from.mailAddress == addr.mailAddress {
                        return true
                    }
                }
                return false
            }
        }
        return false
    }

    public func mailsInFolder(folder: Folder) -> [PersistentMail] {
        let folderMails = DataHandler.handler.allMailsInFolder(key: keyID, contact: ezContact, folder: folder, isSecure: isSecure)
        if folderMails.count == 0 {
            folder.removeFromKeyRecords(self)
        }
        let set = Set<PersistentMail>(folderMails)
        return Array(set).sorted()
    }


    public var inboxMails: [PersistentMail] {
        get {
            let inbox = DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath)
            return mailsInFolder(folder: inbox)
        }
    }


}


private func isEmpty(_ contact: KeyRecord) -> Bool {
    return contact.mails.count == 0
}


public func == (lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if lhs.hasKey && rhs.hasKey {
        if let keyLHS = lhs.key, let keyRHS = rhs.key {
            return keyLHS.keyID == keyRHS.keyID
        }
    }
    if lhs.hasKey != rhs.hasKey {
        return false
    }
    return lhs.contact == rhs.contact
    //return lhs.mails.first!.date == rhs.mails.first!.date && lhs.hasKey == rhs.hasKey && lhs.keyID == rhs.keyID
}

public func < (lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs) {
        return true
    }
    if isEmpty(rhs) {
        return false
    }
    return lhs.mails.first!.date > rhs.mails.first!.date
}

