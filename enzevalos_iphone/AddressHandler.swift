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
    
    static var addresses : [String] = []
    
    static var freqAlgorithm : [String] -> [(UIImage, String, String, UIImage?, UIColor)] = {
        (inserted : [String]) -> [(UIImage, String, String, UIImage?, UIColor)] in
        var cons : [(UIImage,String,String,UIImage?,UIColor)] = []
            do{
                
                try AppDelegate.getAppDelegate().contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey]), usingBlock: {
                    ( c : CNContact, let stop) -> Void in
//                    print(c)
                    for email in c.emailAddresses {
                        let addr = email.value as! String
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
                            color = UIColor.grayColor() //blackColor()
                        }
                        if addr == "" {
                            continue
                        }
                        if !inserted.contains(addr.lowercaseString) {
                            if let name = CNContactFormatter.stringFromContact(c, style: .FullName) {
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
        var list : [(UIImage,String,String,UIImage?,UIColor)] = []
        var entrys = 10
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
            cons.removeAtIndex(index)
        }
        
        return list
    }
    
    static func proveAddress(s : NSString) -> Bool {
        if addresses.contains((s as String).lowercaseString){
            return true
        }
        return KeyHandler.getHandler().addrHasKey(s as String)
    }
    
    static func inContacts( name : String) -> Bool{
        AppDelegate.getAppDelegate().requestForAccess({access in
            print(access)
        })
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName(name), keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey])
                for con in conList {
                    print(con.givenName)
                    print(con.familyName)
                    
                    if (con.givenName+con.familyName).stringByReplacingOccurrencesOfString(" ", withString: "") == name.stringByReplacingOccurrencesOfString(" ", withString: ""){
                        return true
                    }
                }
            }
            catch {
                print("exception")
            }
            print("contacts done")
        }
        else {
            print("no Access!")
        }
        return false
    }
    
    
    
    
    static func getContact(name : String) -> [CNContact]{
        AppDelegate.getAppDelegate().requestForAccess({access in})
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName(name), keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
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
    
    
    static func getContactByID(identifier : String) -> [CNContact]{
        AppDelegate.getAppDelegate().requestForAccess({access in})
        let ids = [identifier]
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                let conList = try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsWithIdentifiers(ids), keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
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
    static func frequentAddresses (inserted : [String]) -> [(UIImage, String, String, UIImage?, UIColor)] {
        return freqAlgorithm(inserted)
    }
    
    static func findContact(econtact: EnzevalosContact)-> [CNContact]{
        var result: [CNContact]
        result = [CNContact]()
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
    
    
    static func proveMatching(result: CNContact, addresses: [MailAddress])-> Bool{
        var match: Bool = false
        for email in result.emailAddresses{
            for adr in addresses{
                let adrRest = email.value as! String
                if adrRest.lowercaseString == adr.mailAddress.lowercaseString {
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
    
    
    static func contactByEmail(mailaddreses: [MailAddress]) -> [CNContact] {
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
            try contacts = AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
        }
        catch {}
        return contacts
    }
}
