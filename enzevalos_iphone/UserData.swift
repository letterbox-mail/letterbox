//
//  UserData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 20/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation



enum Attribute: Int{
    case accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType, imapConnectionType, imapAuthType, smtpConnectionType, smtpAuthType
    
    var defaultValue:AnyObject? {
        switch self {
        case .accountname:
            return Attribute.attributeValues[Attribute.accountname]! //return "Alice"
        case .userName:
            return Attribute.attributeValues[Attribute.userName]! //return "Alice2005"
        case .userAddr:
            return Attribute.attributeValues[Attribute.userAddr]! //return "alice2005@web.de"
        case .userPW:
            return Attribute.attributeValues[Attribute.userPW]! //return "WJ$CE:EtUo3E$"
        case .smtpHostname:
            return Attribute.attributeValues[Attribute.smtpHostname]! //return "smtp.web.de"
        case .smtpPort:
            return 465 as AnyObject?
        case .imapHostname:
            return "mail.enzevalos.de" as AnyObject?
        case .imapPort:
            return 993 as AnyObject?
        case .prefEncryption:
            return "yes" as AnyObject? // yes or no
        case .autocryptType:
            return "p" as AnyObject? // only openpgp 
        case .imapConnectionType:
            return MCOConnectionType.TLS.rawValue as AnyObject?
        case .imapAuthType:
            return MCOAuthType.saslPlain.rawValue as AnyObject?
        case .smtpConnectionType:
            return MCOConnectionType.TLS.rawValue as AnyObject?
        case .smtpAuthType:
            return MCOAuthType.saslPlain.rawValue as AnyObject?
            
        case .publicKey:
            return "" as AnyObject?
        }
    }
    
    static let allAttributes = [accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType]
    static let name = "Charlie"
    static let pw = "tydpawdAwIdPyuc"
    static var attributeValues: [Attribute : AnyObject?] = [.accountname : name as AnyObject?, .userName : name as Optional<AnyObject>, .userAddr : name+"@enzevalos.de" as Optional<AnyObject>, .userPW : pw as Optional<AnyObject>, .smtpHostname : "mail.enzevalos.de" as Optional<AnyObject>, .smtpPort : 465 as Optional<AnyObject>, .imapHostname : "mail.enzevalos.de" as Optional<AnyObject>, .imapPort : 993 as AnyObject?, .prefEncryption : "yes" as AnyObject?, .autocryptType : "p" as AnyObject?, .publicKey : "" as AnyObject?]
    

}


struct UserManager{
    static func storeUserValue(_ value: AnyObject?, attribute: Attribute) {
        UserDefaults.standard.set(value, forKey: "\(attribute.rawValue)")
        UserDefaults.standard.synchronize()
    }
    
    static func loadUserValue(_ attribute: Attribute) -> AnyObject?{
        let value = UserDefaults.standard.value(forKey: "\(attribute.rawValue)")
        if((value) != nil){
            return value as AnyObject?
        }
        else{
            _ = storeUserValue(attribute.defaultValue, attribute: attribute)
            return attribute.defaultValue

        }
    }
    
    static func loadImapAuthType() -> MCOAuthType {
        if let auth = UserManager.loadUserValue(Attribute.imapAuthType) as? Int, auth != 0 {
            return MCOAuthType.init(rawValue: auth)
        }
        return []
    }
    
    static func loadSmtpAuthType() -> MCOAuthType {
        if let auth = UserManager.loadUserValue(Attribute.smtpAuthType) as? Int, auth != 0 {
            return MCOAuthType.init(rawValue: auth)
        }
        return []
    }
    
    static func resetUserValues(){
        for a in Attribute.allAttributes {
            storeUserValue(a.defaultValue, attribute: a)
            //UserDefaults.standard.removeObject(forKey: "\(a.hashValue)")
        }
    }
}

