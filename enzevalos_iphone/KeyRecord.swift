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

public class KeyRecord: Record {
    /*
     A record contains a signing key (or none because of insecure communication), a contact (inlucding mail-addresses) and mails.
     For each key we have a different record for mailboxes. Mails and contact are affliate with the key.
     Each mail is signed with the key or unsigned. The contact contains the ''from-'' mail-addresses of signed mails (or unsigned).
     */

    let key: String?

    public var addresses: [MailAddress] = [MailAddress]()

    public var name: String {
        return ezContact.name
    }
    public var hasKey: Bool {
        return key != nil
    }

    public var isVerified: Bool {
        if let key = self.key {
            if let keywrapper = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)?.getKey(key) {
                return keywrapper.verified
            }

        }
        return false
    }


    public var mails: [Mail] = [Mail]()


    public var ezContact: EnzevalosContact

    public var cnContact: CNContact? {
        return ezContact.cnContact
    }

    public init(contact: EnzevalosContact, key: String?) {
        self.ezContact = contact
        self.key = key
        self.mails = [Mail] ()
    }

    public var image: UIImage {
        return ezContact.getImageOrDefault()
    }
    public var color: UIColor {
        return ezContact.getColor()
    }


    public init(mail: Mail) {
        if(mail.isSecure) {
            self.key = mail.from.keyID
        }
            else {
            self.key = nil
        }
        mails.append(mail)
        mails.sortInPlace()
        self.ezContact = mail.from.contact
        addNewAddress(mail.from)        
    }

    public static func deleteRecordFromRecordArray(records: [KeyRecord], delRecord: KeyRecord) -> [KeyRecord] {
        var myrecords = [KeyRecord](records)
        let index = indexInRecords(myrecords, record: delRecord)
        if index >= 0 {
            myrecords.removeAtIndex(index)
        }
        return myrecords
    }

    public static func indexInRecords(records: [KeyRecord], record: KeyRecord) -> Int {
        for (index, r) in records.enumerate() {
            if (matchAddresses(r, record2: record) && r.hasKey == record.hasKey && r.key == record.key) {
                return index
            }
        }
        return -1
    }

    private func isInRecords(records: [KeyRecord]) -> Bool {
        if KeyRecord.indexInRecords(records, record: self) >= 0 {
            return true
        }
        return false
    }


    private static func matchAddresses(record1: KeyRecord, record2: KeyRecord) -> Bool {
        for adr1 in record1.addresses {
            for adr2 in record2.addresses {
                if adr1.mailAddress == adr2.mailAddress {
                    return true
                }
            }
        }
        return false
    }




    public func showInfos() {
        print("-----------------")
        print("Name: \(ezContact.displayname) | State: \(hasKey) | #Mails: \(mails.count)")
        print("First mail: \(mails.first?.uid) | Adr: \(mails.first?.from.address) | date: \(mails.first?.date.description) ")
        print("subj: \(mails.first?.subject?.capitalizedString)")
    }

    public func addNewAddress(adr: MailAddress) -> Bool {
        for a in addresses {
            if a.mailAddress == adr.mailAddress {
                return false
            }
        }
        addresses.append(adr)
        return true
    }

    public func addNewMail(mail: Mail) -> Bool {
        //TODO: signed only mails are dropped ??
        if mail.isSecure && self.hasKey {
            if mail.from.keyID == self.key {
                mails.append(mail)
                mails.sortInPlace()
                addNewAddress(mail.from)
                return true
            }
            return false

        }
            else if mail.isSecure && !self.hasKey || !mail.isSecure && self.hasKey {
            return false
        }

        if ezContact.getAddress(mail.from.address) != nil {
            for m in mails {
                if m.uid == mail.uid {
                    return true
                }
                    else if m.uid < mail.uid {
                    break
                }
            }


            mails.append(mail)
            mails.sortInPlace()
            addNewAddress(mail.from)
            return true
        }
        return false
    }

    public func getImageOrDefault() -> UIImage {
        return ezContact.getImageOrDefault()
    }

}



private func isEmpty(contact: KeyRecord) -> Bool {
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
