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
    
    static var addresses : [String] = []//["jakob.bode@fu-berlin.de", "oliver.wiese@fu-berlin.de", "jo.lausch@fu-berlin.de", "test"]
    static var freqAlgorithm : [String] -> [(UIImage, String, String, UIImage?, UIColor)] = {
        (inserted : [String]) -> [(UIImage, String, String, UIImage?, UIColor)] in
            /*do{
                var cont = try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName("Jakob Bode"), keysToFetch: [/*CNContactGivenNameKey, CNContactFamilyNameKey, CNContactMiddleNameKey*/CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
                return [(cont[cont.startIndex].getImageOrDefault(),"Jakob", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob Bode", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob B.", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob Simon Bode", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob Bode", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob B.", "jakob.bode@fu-berlin.de"), (cont[cont.startIndex].getImageOrDefault(),"Jakob Simon Bode", "jakob.bode@fu-berlin.de")]
            }
            catch {
                return []
            }*/
        var cons : [(UIImage,String,String,UIImage?,UIColor)] = []
            do{
                
                try AppDelegate.getAppDelegate().contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey]), usingBlock: {
                    (let c : CNContact, let stop) -> Void in
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
        return KeyHandler.getHandler().addrHasKey(s as String)//inContacts(s as String)
        //return false
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
        AppDelegate.getAppDelegate().requestForAccess({access in
            print(access)
        })
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
    
    static func frequentAddresses (inserted : [String]) -> [(UIImage, String, String, UIImage?, UIColor)] {
                                    /*[insertedEmail]             -> [(contactImage, name, address, emailLabelImage, backgroundcolor)]*/
        //(persistente) liste von Kontakten abfragen
        return freqAlgorithm(inserted)
    }
    
//    static func contactByEmail(email: String) -> CNContact? {
//        var contacts: [CNContact] = []
//        let predicate = NSPredicate { (evaluatedObject, bindings) -> Bool in
//            guard let evaluatedContact = evaluatedObject as? CNContact else {
//                return false
//            }
//            return Set(evaluatedContact.emailAddresses.map{$0.identifier}).contains(email)
//        }
//        do{
//            try contacts = AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
//        }
//        catch {}
//        print(contacts)
//        return contacts.first
//    }
}
