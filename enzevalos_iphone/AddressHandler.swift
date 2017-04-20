//
//  AddressHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 14.07.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import Foundation
import Contacts
import UIKit.UIImage

class AddressHandler {
    
    static var addresses: [String] = []
    
    static var freqAlgorithm: ([String]) -> [(UIImage, String, String, UIImage?, UIColor)] = {
        (inserted : [String]) -> [(UIImage, String, String, UIImage?, UIColor)] in
        var cons : [(UIImage,String,String,UIImage?,UIColor)] = []
            do{
                
                try AppDelegate.getAppDelegate().contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor]), usingBlock: {
                    ( c : CNContact, stop) -> Void in
//                    print(c)
                    for email in c.emailAddresses {
                        let addr = email.value as String
                        var type : UIImage? = nil
                        if c.emailAddresses.count > 1 {
                            if email.label == "_$!<Work>!$_"{
                                type = UIImage(named: "work2_white")!
                            }
                            else if email.label == "_$!<Home>!$_"{
                                type = UIImage(named: "home2_white")!
                            }
                            else if email.label == "_$!<iCloud>!$_"{
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
                            }
                            else {
                                cons.append((c.getImageOrDefault(), "NO NAME", addr, type, color))
                            }
                        }
                    }
                    })
            }
            catch {}
        var list: [(UIImage,String,String,UIImage?,UIColor)] = []
        var entrys = CollectionDataDelegate.maxFrequent
        if cons.count < entrys {
            entrys = cons.count
        }
        if entrys <= 0 {
            return []
        }
        for i in 0...entrys-1 {
            //let index = abs(Int(arc4random())) % cons.count
            let index = i % cons.count
            list.append(cons[index])
            cons.remove(at: index)
        }
        
        return list
    }
    
    static var freqAlgorithm2: ([String]) -> [(UIImage, String, String, UIImage?, UIColor)] = {
        (inserted : [String]) -> [(UIImage, String, String, UIImage?, UIColor)] in
        
        var cons = DataHandler.handler.contacts
        var list: [(UIImage,String,String,UIImage?,UIColor)] = []
        
        for con: EnzevalosContact in cons {
            if list.count >= CollectionDataDelegate.maxFrequent {
                break
            }
            var insertedEntry = false
            var address = con.getMailAddresses()[0]
            for addr in con.getMailAddresses() {
                if inserted.contains(addr.mailAddress) {
                    insertedEntry = true
                }
                if addr.hasKey {
                    address = addr
                }
            }
            if !insertedEntry {
                if let cn = con.cnContact {
                    var addrType: UIImage? = nil
                    
                    if address.label.label == "_$!<Work>!$_" {
                        addrType = UIImage(named: "work2_white")!
                    }
                    if address.label.label == "_$!<Home>!$_" {
                        addrType = UIImage(named: "home2_white")!
                    }
                    
                    var color = cn.getColor()
                    if cn.thumbnailImageData != nil {
                        color = UIColor.gray //blackColor()
                    }
                    
                    //TODO: Add Image in EnzevalosContact
                    var entry = (cn.getImageOrDefault(), con.displayname!, address.mailAddress, addrType, color)
                    
                    list.append(entry)
                }
            }
        }
        
        
        
        
        /*var entrys = CollectionDataDelegate.maxFrequent
        if cons.count < entrys {
            entrys = cons.count
        }
        if entrys <= 0 {
            return []
        }
        for i in 0...entrys-1 {
            //let index = abs(Int(arc4random())) % cons.count
            let index = i % cons.count
            list.append(cons[index])
            cons.remove(at: index)
        }*/
        
        return list
    }
    
    static func proveAddress(_ s: NSString) -> Bool {
        if addresses.contains((s as String).lowercased()){
            return true
        }
        return EnzevalosEncryptionHandler.hasKey(DataHandler.handler.getContactByAddress((s as String).lowercased()))
    }
    
    static func inContacts(_ name: String) -> Bool{
        AppDelegate.getAppDelegate().requestForAccess({access in })
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: name), keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor])
                for con in conList {
                    print(con.givenName)
                    print(con.familyName)
                    
                    if (con.givenName+con.familyName).replacingOccurrences(of: " ", with: "") == name.replacingOccurrences(of: " ", with: ""){
                        return true
                    }
                }
            }
            catch {
                print("exception")
            }
        }
        else {
            print("no Access!")
        }
        return false
    }
    
    
    
    
    static func getContact(_ name: String) -> [CNContact]{
        AppDelegate.getAppDelegate().requestForAccess({access in})
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: name), keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
                return conList
            }
            catch {
                print("exception")
            }
            print("contacts done")
        }
        else {
            print("no Access!")
        }
        return []
    }
    
    
    static func getContactByID(_ identifier: String) -> [CNContact]{
        AppDelegate.getAppDelegate().requestForAccess({access in})
        let ids = [identifier]
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(withIdentifiers: ids), keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
                return conList
            }
            catch {
                print("exception")
            }
            print("contacts done")
        }
        else {
            print("no Access!")
        }
        return []
    }

    /*          [insertedEmail] -> [(contactImage, name, address, emailLabelImage, backgroundcolor)] */
    static func frequentAddresses (_ inserted: [String]) -> [(UIImage, String, String, UIImage?, UIColor)] {
        return freqAlgorithm2(inserted)
    }
    
    static func findContact(_ econtact: EnzevalosContact)-> [CNContact]{
        var result = [CNContact]()
        if let identifier = econtact.cnidentifier {
            // 1. Look up identifier string
            result = getContactByID(identifier)
        }
        if result.count == 0{
            if let name = econtact.displayname{
                // 2. look for name
                let query = getContact(name)
                for res in query{
                    if (proveMatching(res, addresses: econtact.getMailAddresses())){
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
    
    
    static func proveMatching(_ result: CNContact, addresses: [MailAddress])-> Bool{
        var match: Bool = false
        for email in result.emailAddresses{
            for adr in addresses{
                let adrRest = email.value as String
                if adrRest.lowercased() == adr.mailAddress.lowercased() {
                    match = true
                    break
                }
            }
            if match{
                break
            }
        }
        return match
    }
    
    
    static func contactByEmail(_ mailaddreses: [MailAddress]) -> [CNContact] {
        var contacts: [CNContact] = []
        let predicate = NSPredicate { (evaluatedObject, bindings) -> Bool in
            guard let evaluatedContact = evaluatedObject as? CNContact else {
               return false
            }
            var exists: Bool
            exists = false
            for adr in mailaddreses{
                let contains = Set(evaluatedContact.emailAddresses.map{$0.identifier}).contains(adr.mailAddress)
                exists = (exists || contains)

            }
            return exists
        }
        do{
            try contacts = AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
        }
        catch {}
        return contacts
    }
}
