//
//  AddressHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 14.07.16.
//  //  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import Contacts
import UIKit.UIImage

class AddressHandler {

    static var addresses: [String] = []

    static var freqAlgorithm: ([String]) -> [(UIImage, String, String, UIImage?, UIColor)] = {
        (inserted: [String]) -> [(UIImage, String, String, UIImage?, UIColor)] in
        var cons: [(UIImage, String, String, UIImage?, UIColor)] = []
        do {

            try AppDelegate.getAppDelegate().contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor]), usingBlock: {
                    (c: CNContact, stop) -> Void in
                    for email in c.emailAddresses {
                        let addr = email.value as String
                        var type: UIImage? = nil
                        if c.emailAddresses.count > 1 {
                            if email.label == "_$!<Work>!$_" {
                                type = UIImage(named: "work2_white")!
                            } else if email.label == "_$!<Home>!$_" {
                                type = UIImage(named: "home2_white")!
                            } else if email.label == "_$!<iCloud>!$_" {
                                //TODO: appleIcon hinzufügen
                            }
                        }
                        var color = c.getColor()
                        if c.thumbnailImageData != nil {
                            color = UIColor.gray //blackColor()
                        }
                        if addr == "" {
                            continue
                        }
                        if !inserted.contains(addr.lowercased()) {
                            if let name = CNContactFormatter.string(from: c, style: .fullName) {
                                cons.append((c.getImageOrDefault(), name, addr, type, color))
                            } else {
                                cons.append((c.getImageOrDefault(), "NO NAME", addr, type, color))
                            }
                        }
                    }
                })
        }
        catch { }
        var list: [(UIImage, String, String, UIImage?, UIColor)] = []
        var entrys = CollectionDataDelegate.maxFrequent
        if cons.count < entrys {
            entrys = cons.count
        }
        if entrys <= 0 {
            return []
        }
        for i in 0...entrys - 1 {
            //let index = abs(Int(arc4random())) % cons.count
            let index = i % cons.count
            list.append(cons[index])
            cons.remove(at: index)
        }

        return list
    }

    static var freqAlgorithm2: ([String]) -> [(UIImage, String, String, UIImage?, UIColor)] = {
        (inserted: [String]) -> [(UIImage, String, String, UIImage?, UIColor)] in

        var cons = DataHandler.handler.folderRecords(folderPath: UserManager.backendInboxFolderPath)
        var list: [(UIImage, String, String, UIImage?, UIColor)] = []
        var localInserted = inserted

        for con: KeyRecord in cons {
            if list.count >= CollectionDataDelegate.maxFrequent {
                break
            }
            var insertedEntry = false
            var address = con.ezContact.getMailAddresses()[0]
            for addr in con.ezContact.getMailAddresses() {
                if localInserted.contains(addr.mailAddress) {
                    insertedEntry = true
                }
                if addr.hasKey {
                    address = addr
                }
            }
            if !insertedEntry {
                var addrType: UIImage? = nil

                if address.label.label == "_$!<Work>!$_" {
                    addrType = UIImage(named: "work2_white")!
                }
                if address.label.label == "_$!<Home>!$_" {
                    addrType = UIImage(named: "home2_white")!
                }
                if let cn = con.cnContact {
                    var color = cn.getColor()
                    if cn.thumbnailImageData != nil {
                        color = UIColor.gray //blackColor()
                    }

                    var entry = (cn.getImageOrDefault(), con.ezContact.displayname!, address.mailAddress, addrType, color)

                    list.append(entry)
                    localInserted.append(address.mailAddress)
                } else {
                    var entry = (con.ezContact.getImageOrDefault(), con.ezContact.displayname ?? address.mailAddress, address.mailAddress, addrType, con.ezContact.getColor())
                    list.append(entry)
                    localInserted.append(address.mailAddress)
                }
            }
        }



        return list
    }

    static func getContact(_ name: String) -> [CNContact] {
        if name == "" {
            return []
        }
        AppDelegate.getAppDelegate().requestForAccess({ access in })
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: name), keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
                return conList
            } catch {
                print("exception in contacts get for name: \(name)")
            }
        } else {
            print("no Access!")
        }
        return []
    }

    static func getContactByID(_ identifier: String) -> [CNContact] {
        AppDelegate.getAppDelegate().requestForAccess({ access in })
        let ids = [identifier]
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(withIdentifiers: ids), keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
                return conList
            } catch {
                print("exception in contacts")
            }
        } else {
            print("no Access!")
        }
        return []
    }

    /*          [insertedEmail] -> [(contactImage, name, address, emailLabelImage, backgroundcolor)] */
    static func frequentAddresses (_ inserted: [String]) -> [(UIImage, String, String, UIImage?, UIColor)] {
        let cons = DataHandler.handler.folderRecords(folderPath: UserManager.backendInboxFolderPath)
        var list: [(UIImage, String, String, UIImage?, UIColor)] = []
        var localInserted = inserted

        for con: KeyRecord in cons {
            if list.count >= CollectionDataDelegate.maxFrequent {
                break
            }
            var insertedEntry = false
            var address = con.ezContact.getMailAddresses()[0]
            for addr in con.ezContact.getMailAddresses() {
                if localInserted.contains(addr.mailAddress) {
                    insertedEntry = true
                }
                if addr.hasKey {
                    address = addr
                }
            }
            if !insertedEntry {
                var addrType: UIImage? = nil

                if address.label.label == "_$!<Work>!$_" {
                    addrType = UIImage(named: "work2_white")!
                }
                if address.label.label == "_$!<Home>!$_" {
                    addrType = UIImage(named: "home2_white")!
                }
                if let cn = con.cnContact {
                    var color = cn.getColor()
                    if cn.thumbnailImageData != nil {
                        color = UIColor.gray //blackColor()
                    }
                    let entry = (cn.getImageOrDefault(), con.ezContact.displayname!, address.mailAddress, addrType, color)

                    list.append(entry)
                    localInserted.append(address.mailAddress)
                } else {
                    let entry = (con.ezContact.getImageOrDefault(), con.ezContact.displayname ?? address.mailAddress, address.mailAddress, addrType, con.ezContact.getColor())
                    list.append(entry)
                    localInserted.append(address.mailAddress)
                }
            }
        }

        return list
    }

    static func findContact(_ econtact: EnzevalosContact) -> [CNContact] {
        var result = [CNContact]()
        if let identifier = econtact.cnidentifier {
            // 1. Look up identifier string
            result = getContactByID(identifier)
        }
        if result.count == 0 {
            if let name = econtact.displayname?.trimmingCharacters(in: .decimalDigits) {
                // 2. look for name
                let query = getContact(name)
                for res in query {
                    if (proveMatching(res, addresses: econtact.getMailAddresses())) {
                        result.append(res)
                    }
                }
            }
        }
        if result.count == 0 {
            // 3. look for mail addresses
            result = contactByEmail(econtact.getMailAddresses())
        }
        return result
    }

    static func proveMatching(_ result: CNContact, addresses: [MailAddress]) -> Bool {
        for email in result.emailAddresses {
            for adr in addresses {
                let adrRest = email.value as String
                if adrRest.lowercased() == adr.mailAddress.lowercased() {
                    return true
                }
            }
        }
        return false
    }

    static func contactByEmail(_ mailaddreses: [MailAddress]) -> [CNContact] {
        var contacts: [CNContact] = []

        let fetchRequest = CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])

        do {
            try AppDelegate.getAppDelegate().contactStore.enumerateContacts(with: fetchRequest, usingBlock: { (contact, _) in
                for addr in mailaddreses {
                    let contains = Set(contact.emailAddresses.map({ $0.value as String })).contains(addr.mailAddress)
                    if contains {
                        contacts.append(contact)
                    }
                }
            })
        } catch {
            print("Problem while accessing contacts by email")
        }

        return contacts
    }


    static func updateCNContacts() {
        let enzContacts = DataHandler.handler.getContacts()

        for contact in enzContacts {
            let contacts = findContact(contact)
            if contact.cnContact == nil {
                if contacts.count > 0 {
                    contact.cnidentifier = contacts.first?.identifier
                }
            }
            else if contacts.count > 0 && contact.cnContact != nil {
                contact.cnidentifier = nil
            }
            else if contacts.count > 0 {
                let cnContact = contacts.first
                if let addresses = cnContact?.getMailAddresses() {
                    var hasSame = false
                    for adr1 in contact.getMailAddresses() {
                        var found = false
                        for adr2 in addresses {
                            if adr1.mailAddress == adr2.mailAddress {
                                found = true
                                break
                            }
                        }
                        if found {
                            hasSame = true
                        }
                    }
                    if !hasSame {
                        contact.cnidentifier = nil
                    }
                }
                else {
                    contact.cnidentifier = nil
                }
                
                
            }
        }
        DataHandler.handler.save(during: "updateCNContacts")
    }
}
