//
//  EnzevalosContact+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import UIKit
import Contacts

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}


@objc(EnzevalosContact)
open class EnzevalosContact: NSManagedObject, Contact, Comparable {

    override open var debugDescription: String {
        get {
            var string = ""
            string = string + "Name: \(name) #Keys: \(publicKeys.count) #Addr: \(addresses.count) \n Addresses: \n"
            for addr in addresses {
                if let a = addr as? Mail_Address {
                    string = string + a.address + "\n"
                }
            }
            string = string + "public Keys: \n"
            for pk in publicKeys {
                string = string + "\(pk.keyID) \n"
            }
            return string
        }
    }

    open var name: String {
        if let name = nameOptional {
            return name
        } else if let displayname = displayname {
            return displayname
        } else {
            return NSLocalizedString("noName", comment: "We have no name for this one")
        }
    }

    open var nameOptional: String? {
        var name = String()

        if let cnc = cnContact {
            if cnc.givenName.count > 0 {
                name += cnc.givenName
            }
            if cnc.familyName.count > 0 {
                if name.count > 0 {
                    name += " "
                }
                name += cnc.familyName
            }
        }
        if name.count > 0 {
            return name
        } else {
            return nil
        }
    }

    open var to: [PersistentMail] {
        get {
            var mails = [PersistentMail]()
            for adr in addresses {
                if let a = adr as? Mail_Address, let to = a.to {
                    for m in to {
                        mails.append(m as! PersistentMail)
                    }
                }
            }
            return mails
        }
    }

    open var bcc: [PersistentMail] {
        get {
            var mails = [PersistentMail]()
            for adr in addresses {
                if let a = adr as? Mail_Address, let bcc = a.bcc {
                    for m in bcc {
                        mails.append(m as! PersistentMail)
                    }
                }
            }
            return mails
        }
    }



    open var cc: [PersistentMail] {
        get {
            var mails = [PersistentMail]()
            for adr in addresses {
                if let a = adr as? Mail_Address, let cc = a.cc {
                    for m in cc {
                        mails.append(m as! PersistentMail)
                    }
                }
            }
            return mails
        }
    }

    open var from: [PersistentMail] {
        get {
            var mails = [PersistentMail]()
            for adr in addresses {
                if let a = adr as? Mail_Address, let from = a.from {
                    for m in from {
                        mails.append(m as! PersistentMail)
                    }
                }
            }
            return mails
        }
    }

    var publicKeys: Set<PersistentKey> {
        get {
            var pks = Set<PersistentKey>()
            for adr in getMailAddresses() {
                pks = pks.union(adr.publicKeys)
            }
            return pks
        }
    }

    open var records: [KeyRecord] {
        get {
            if let krecords = self.keyrecords as? Set<KeyRecord> {
                return Array(krecords)
            }
            return []
        }

    }
    open var hasKey: Bool {
        get {
            for item in addresses {
                let adr = item as! MailAddress
                if adr.hasKey {
                    return true
                }
            }
            return false
        }
    }

    open var cnContact: CNContact? {
        get {
            if let cn = cnidentifier {
                let contacts = AddressHandler.getContactByID(cn)
                if contacts.count > 0 {
                    return contacts.first
                }
            }
            return nil
        }
    }

    open var newCnContact: CNContact {
        let con = CNMutableContact()
        let name = self.displayname
        if let n = name {
            let nameArray = n.split(separator: " ").map(String.init)
            switch nameArray.count {
            case 1:
                con.givenName = nameArray.first!
            case 2..<20: // who has more than two names?!
                con.givenName = nameArray.first!
                con.familyName = nameArray.last!
            default:
                con.givenName = "NO"
                con.familyName = "NAME"
            }
        }

        let adr: Mail_Address
        adr = addresses.anyObject() as! Mail_Address
        con.emailAddresses.append(CNLabeledValue(label: CNLabelOther, value: adr.address as NSString))
        return con
    }

    func getAddress(_ address: String) -> Mail_Address? {
        var addr: Mail_Address
        for obj in addresses {
            addr = obj as! Mail_Address
            if(addr.address == address) {
                return addr
            }
        }
        return nil
    }

    func getAddressByMCOAddress(_ mcoaddress: MCOAddress) -> Mail_Address? {
        if (mcoaddress.mailbox) != nil {
            return getAddress(mcoaddress.mailbox.lowercased())
        }
        return nil
    }

    open func getMailAddresses() -> [MailAddress] {
        var adr = [MailAddress] ()
        for a in addresses {
            let b = a as! Mail_Address
            adr.append(b)
        }
        return adr
    }

    func isAddress(mailadr: String) -> Bool {
        for adr in getMailAddresses() {
            if mailadr.lowercased() == adr.mailAddress.lowercased() {
                return true
            }
        }
        return false
    }
}

private func isEmpty(_ contact: EnzevalosContact) -> Bool {
    let mails = contact.from
    if(mails.count == 0) {
        return true
    }
    return false
}

func == (lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs) {
        return false
    }
    if isEmpty(rhs) {
        return false
    }
    let mailLHS = lhs.from.last
    let mailRHS = rhs.from.last

    return mailLHS == mailRHS
}

public func < (lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs) {
        return true
    }
    if isEmpty(rhs) {
        return false
    }
    let mailLHS = lhs.from.last
    let mailRHS = rhs.from.last

    return mailLHS < mailRHS
}
