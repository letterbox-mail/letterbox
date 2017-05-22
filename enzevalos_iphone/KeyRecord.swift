//
//  KeyRecord.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts
import UIKit

open class KeyRecord: Record {

    /*
     A record contains a signing key (or none because of insecure communication), a contact (inlucding mail-addresses) and mails.
     For each key we have a different record for mailboxes. Mails and contact are affliate with the key.
     Each mail is signed with the key or unsigned. The contact contains the ''from-'' mail-addresses of signed mails (or unsigned).
     */

    let key: String?

    open var addresses: [MailAddress] = [MailAddress]()

    open var name: String {
        return ezContact.name
    }
    open var hasKey: Bool {
        // Public encryption key. May missing for secure mails since mail is only signed and encrypted
        return key != nil
    }
    
    open var isSecure: Bool = false

    open var isVerified: Bool {
        if let key = self.key {
            if let keywrapper = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)?.getKey(key) {
                return keywrapper.verified
            }

        }
        return false
    }


    open var mails: [PersistentMail] = [PersistentMail]()


    open var ezContact: EnzevalosContact

    open var cnContact: CNContact? {
        return ezContact.cnContact
    }

    open var image: UIImage {
        return ezContact.getImageOrDefault()
    }
    open var color: UIColor {
        return ezContact.getColor()
    }


    public init(mail: PersistentMail) {
        self.isSecure = mail.isSecure
        if(mail.isSecure && mail.from.hasKey) {
            self.key = mail.from.keyID
        }
        else {
            self.key = nil
        }
        mails.append(mail)
        mails.sort()
        self.ezContact = mail.from.contact!
        _ = addNewAddress(mail.from)
    }

    open static func deleteRecordFromRecordArray(_ records: [KeyRecord], delRecord: KeyRecord) -> [KeyRecord] {
        var myrecords = [KeyRecord](records)
        let index = indexInRecords(myrecords, record: delRecord)
        if index >= 0 {
            myrecords.remove(at: index)
        }
        return myrecords
    }

    open static func indexInRecords(_ records: [KeyRecord], record: KeyRecord) -> Int {
        for (index, r) in records.enumerated() {
            if (matchAddresses(r, record2: record) && r.hasKey == record.hasKey && r.key == record.key) {
                return index
            }
        }
        return -1
    }

    private func isInRecords(_ records: [KeyRecord]) -> Bool {
        if KeyRecord.indexInRecords(records, record: self) >= 0 {
            return true
        }
        return false
    }


    private static func matchAddresses(_ record1: KeyRecord, record2: KeyRecord) -> Bool {
        for adr1 in record1.addresses {
            for adr2 in record2.addresses {
                if adr1.mailAddress == adr2.mailAddress {
                    return true
                }
            }
        }
        return false
    }




    open func showInfos() {
        print("-----------------")
        print("Name: \(ezContact.displayname) | State: \(hasKey) | #Mails: \(mails.count)")
        print("First mail: \(mails.first?.uid) | Adr: \(mails.first?.from.mailAddress) | date: \(mails.first?.date.description) ")
        print("subj: \(mails.first?.subject?.capitalized)")
    }

    open func addNewAddress(_ adr: MailAddress) -> Bool {
        for a in addresses {
            if a.mailAddress == adr.mailAddress {
                return false
            }
        }
        addresses.append(adr)
        return true
    }

    open func addNewMail(_ mail: PersistentMail) -> Bool {
        // TODO: signed only mails are dropped ??
        if mail.isSecure && self.isSecure {
            if mail.from.keyID == self.key {
                mails.append(mail)
                mails.sort()
                _ = addNewAddress(mail.from)
                return true
            }
            return false

        }
        else if mail.isSecure != self.isSecure {
            return false
        }

        if ezContact.getAddress(mail.from.mailAddress) != nil {
            for m in mails {
                if m.uid == mail.uid {
                    return true
                }
                    else if m.uid < mail.uid {
                    break
                }
            }
            mails.append(mail)
            mails.sort()
            _ = addNewAddress(mail.from)
            return true
        }
        return false
    }

    open func getImageOrDefault() -> UIImage {
        return ezContact.getImageOrDefault()
    }

}



private func isEmpty(_ contact: KeyRecord) -> Bool {
    return contact.mails.count == 0
}


public func == (lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs) {
        return false
    }
    if isEmpty(rhs) {
        return false
    }
    return lhs.mails.first!.date == rhs.mails.first!.date && lhs.hasKey == rhs.hasKey && lhs.key == rhs.key
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
