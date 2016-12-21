//
//  UserData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 20/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation



enum Attribute: Int{
    case Accountname, UserName, UserAddr, UserPW, SMTPHostname, SMTPPort, IMAPHostname, IMAPPort, PrefEncryption, PublicKey, AutocryptType
    
    var defaultValue:AnyObject? {
        switch self {
        case .Accountname:
            return "Alice"
        case .UserName:
            return "Alice"
        case .UserAddr:
            return "alice2005@web.de"
        case .UserPW:
            return "WJ$CE:EtUo3E$"
        case .SMTPHostname:
            return "smtp.web.de"
        case .SMTPPort:
            return 587
        case .IMAPHostname:
            return "imap.web.de"
        case .IMAPPort:
            return 993
        case .PrefEncryption:
            return "yes" // yes or no
        case .AutocryptType:
            return "p" // only openpgp 
            
        case .PublicKey:
            let pgpkey = KeyHandler.createHandler().getKeyByAddr(UserManager.loadUserValue(.UserAddr)as! String)
            do{
                let export = try pgpkey?.key.export()
                return export?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithCarriageReturn)
            } catch _ {
                print("No key")
                //TODO: Create Key?!
            }
            
            return ""
        }
    }
    
    static let allAttributes = [Accountname, UserName, UserAddr, UserPW, SMTPHostname, SMTPPort, IMAPHostname, IMAPPort, PrefEncryption, PublicKey, AutocryptType]
   
}


struct UserManager{
    static func storeUserValue(value: AnyObject?, attribute: Attribute) -> Bool{
        NSUserDefaults.standardUserDefaults().setValue(value, forKey: "\(attribute.hashValue)")
        NSUserDefaults.standardUserDefaults().synchronize()
        return true
    }
    
    static func loadUserValue(attribute: Attribute) -> AnyObject?{
        // TODO: Cache data
        let value = NSUserDefaults.standardUserDefaults().valueForKey("\(attribute.hashValue)")
        if((value) != nil){
            return value
        }
        else{
            storeUserValue(attribute.defaultValue, attribute: attribute)
            return attribute.defaultValue

        }
    }
    
    static func resetUserValues(){
        for a in Attribute.allAttributes {
            NSUserDefaults.standardUserDefaults().removeObjectForKey("\(a.hashValue)")
        }
    }
}

