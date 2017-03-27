//
//  UserData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 20/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation



enum Attribute: Int{
    case Accountname, UserName, UserAddr, UserPW, SMTPHostname, SMTPPort, IMAPHostname, IMAPPort, PrefEncryption, PublicKey, AutocryptType, ConnectionType, AuthType
    
    var defaultValue:AnyObject? {
        switch self {
        case .Accountname:
            return Attribute.attributeValues[Attribute.Accountname]! //return "Alice"
        case .UserName:
            return Attribute.attributeValues[Attribute.UserName]! //return "Alice2005"
        case .UserAddr:
            return Attribute.attributeValues[Attribute.UserAddr]! //return "alice2005@web.de"
        case .UserPW:
            return Attribute.attributeValues[Attribute.UserPW]! //return "WJ$CE:EtUo3E$"
        case .SMTPHostname:
            return Attribute.attributeValues[Attribute.SMTPHostname]! //return "smtp.web.de"
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
        case .ConnectionType:
            return MCOConnectionType.StartTLS.rawValue
        case .AuthType:
            return MCOAuthType.SASLPlain.rawValue
            
        case .PublicKey:
            return ""
        }
    }
    
    static let allAttributes = [Accountname, UserName, UserAddr, UserPW, SMTPHostname, SMTPPort, IMAPHostname, IMAPPort, PrefEncryption, PublicKey, AutocryptType]
    static var attributeValues: [Attribute : AnyObject?] = [.Accountname : "Alice", .UserName : "Alice2005", .UserAddr : "alice2005@web.de", .UserPW : "WJ$CE:EtUo3E$", .SMTPHostname : "smtp.web.de", .SMTPPort : 587, .IMAPHostname : "imap.web.de", .IMAPPort : 993, .PrefEncryption : "yes", .AutocryptType : "p", .PublicKey : ""]
}


struct UserManager{
    static func storeUserValue(value: AnyObject?, attribute: Attribute) -> Bool{
        NSUserDefaults.standardUserDefaults().setValue(value, forKey: "\(attribute.hashValue)")
        NSUserDefaults.standardUserDefaults().synchronize()
        return true
    }
    
    static func loadUserValue(attribute: Attribute) -> AnyObject?{
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

