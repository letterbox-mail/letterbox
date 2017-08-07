//
//  UserData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 20/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation



enum Attribute: Int{
    case accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType, imapConnectionType, imapAuthType, smtpConnectionType, smtpAuthType, sentFolderPath, draftFolderPath, trashFolderPath, inboxFolderPath, archiveFolderPath
    
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
            return Attribute.attributeValues[Attribute.smtpPort]!
        case .imapHostname:
            return Attribute.attributeValues[Attribute.imapHostname]!
        case .imapPort:
            return Attribute.attributeValues[Attribute.imapPort]!
        case .prefEncryption:
            return "mutal" as AnyObject? // yes or no
        case .autocryptType:
            return "1" as AnyObject? // only openpgp
        case .imapConnectionType:
            return MCOConnectionType.TLS.rawValue as AnyObject?
        case .imapAuthType:
            return MCOAuthType.saslPlain.rawValue as AnyObject?
        case .smtpConnectionType:
             return MCOConnectionType.TLS.rawValue as AnyObject?//startTLS.rawValue
            //return MCOConnectionType.startTLS.rawValue as AnyObject?//startTLS.rawValue
        case .sentFolderPath:
            return NSLocalizedString("Sent", comment: "Default name for the sentFolder") as AnyObject?
        case .draftFolderPath:
            return NSLocalizedString("Drafts", comment: "Default name for the draftFolder") as AnyObject?
        case .trashFolderPath:
            return NSLocalizedString("Trash", comment: "Default name for the trashFolder") as AnyObject?
        case .inboxFolderPath:
            return NSLocalizedString("INBOX", comment: "Default name for the inboxFolder") as AnyObject?
        case .archiveFolderPath:
            return NSLocalizedString("Archive", comment: "Default name for the archiveFolder") as AnyObject?
            
        case .smtpAuthType:
            return MCOAuthType.saslPlain.rawValue as AnyObject?
            
        case .publicKey:
            return "" as AnyObject?
        }
    }
    
    static let allAttributes = [accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType]
    //static var name = "Alice2005@web.de"//"Ullimuelle@web.de"
    //static var pw = "WJ$CE:EtUo3E$"//"dun3bate"
    
    //static let name = "Ullimuelle@web.de"
    //static let pw =  "dun3bate"
   // static let name = "bob"
   // static let pw = "VagotOshaicceov"
   // static let name = "alice"
    //static let pw = "egOavOpeecOntew"
    static let name = "charlie"
    static let pw = "tydpawdAwIdPyuc"
    static var attributeValues:
    //[Attribute : AnyObject?] = [.accountname : name as AnyObject?, .userName : name as Optional<AnyObject>, .userAddr : name as Optional<AnyObject>, .userPW : pw as Optional<AnyObject>, .smtpHostname : "smtp.web.de" as Optional<AnyObject>, .smtpPort : 587 as Optional<AnyObject>, .imapHostname : "imap.web.de" as Optional<AnyObject>, .imapPort : 993 as AnyObject?, .prefEncryption : "yes" as AnyObject?, .autocryptType : "p" as AnyObject?, .publicKey : "" as AnyObject?]
        [Attribute : AnyObject?] = [.accountname : name as AnyObject?, .userName : name as Optional<AnyObject>, .userAddr : name+"@enzevalos.de" as Optional<AnyObject>, .userPW : pw as Optional<AnyObject>, .smtpHostname : "mail.enzevalos.de" as Optional<AnyObject>, .smtpPort : 465 as Optional<AnyObject>, .imapHostname : "mail.enzevalos.de" as Optional<AnyObject>, .imapPort : 993 as AnyObject?, .prefEncryption : "yes" as AnyObject?, .autocryptType : "p" as AnyObject?, .publicKey : "" as AnyObject?]
    

}


struct UserManager{
    
    //Frontend (GUI and providers.json) uses UTF-8 String-Encoding
    //The backend uses because of the definition of IMAP UTF-7 String-Encoding
    static var frontendDraftFolderPath: String {
        get {
            return loadUserValue(Attribute.draftFolderPath) as? String ?? NSLocalizedString("Drafts", comment: "")
        }
    }
    
    static var frontendInboxFolderPath: String {
        get {
            return loadUserValue(Attribute.inboxFolderPath) as? String ?? NSLocalizedString("INBOX", comment: "")
        }
    }
    
    static var frontendSentFolderPath: String {
        get {
            return loadUserValue(Attribute.sentFolderPath) as? String ?? NSLocalizedString("Sent", comment: "")
        }
    }
    
    static var frontendArchiveFolderPath
        : String {
        get {
            return loadUserValue(Attribute.archiveFolderPath) as? String ?? NSLocalizedString("Archive", comment: "")
        }
    }
    
    static var frontendTrashFolderPath: String {
        get {
            return loadUserValue(Attribute.trashFolderPath) as? String ?? NSLocalizedString("Trash", comment: "")
        }
    }
    
    static var backendDraftFolderPath: String {
        get {
            return convertToBackendFolderPath(from: frontendDraftFolderPath)
        }
    }
    
    static var backendSentFolderPath: String {
        get {
            return convertToBackendFolderPath(from: frontendSentFolderPath)
        }
    }
    
    static var backendArchiveFolderPath: String {
        get {
            return convertToBackendFolderPath(from: frontendArchiveFolderPath)
        }
    }
    
    static var backendTrashFolderPath: String {
        get {
            return convertToBackendFolderPath(from: frontendTrashFolderPath)
        }
    }
    
    static var backendInboxFolderPath: String {
        get {
            return convertToBackendFolderPath(from: frontendInboxFolderPath)
        }
    }
    
    //Usable for paths too
    static func convertToFrontendFolderPath(from backendFolderPath: String, with delimiter: String = ".") -> String{
        return (AppDelegate.getAppDelegate().mailHandler.IMAPSession.defaultNamespace.components(fromPath: backendFolderPath) as! [String]).joined(separator: delimiter)
    }
    
    //Usable for paths too
    static func convertToBackendFolderPath(from frontendFolderPath: String) -> String {
        let session = AppDelegate.getAppDelegate().mailHandler.IMAPSession
        if session.defaultNamespace == nil && frontendFolderPath == frontendInboxFolderPath { //FIXME: Dirty Fix for Issue #105
            return "INBOX"
        }
        return AppDelegate.getAppDelegate().mailHandler.IMAPSession.defaultNamespace.path(forComponents: [frontendFolderPath])
    }
    
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

