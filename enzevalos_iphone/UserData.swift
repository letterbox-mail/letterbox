//
//  UserData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 20/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import KeychainAccess



enum Attribute: Int{
    case accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType, imapConnectionType, imapAuthType, smtpConnectionType, smtpAuthType, sentFolderPath, draftFolderPath, trashFolderPath, inboxFolderPath, archiveFolderPath, nextDeadline //used for Logging; determines the earliest next time a log is send to the researchers
    
    var defaultValue:AnyObject? {
        switch self {
            case .prefEncryption:
                return "mutal" as AnyObject? 
            case .autocryptType:
                return "1" as AnyObject? // only openpgp
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
        case .nextDeadline:
            return Date(timeIntervalSinceNow: TimeInterval(Logger.loggingInterval)) as AnyObject?
        default:
            return nil
        }
    }
    
    static let allAttributes = [accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType]
}


struct UserManager{
    
    private static var pwKeyChain: Keychain{
        get{
            return Keychain(service: "Enzevalos/Password")
        }
    }
    
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
        if attribute == Attribute.userPW {
            let pw = value as! String
            pwKeyChain["userPW"] = pw
        }
        else{
            UserDefaults.standard.set(value, forKey: "\(attribute.rawValue)")
            UserDefaults.standard.synchronize()
    
        }
    }
    
    static func loadUserValue(_ attribute: Attribute) -> AnyObject?{
        if attribute == Attribute.userPW {
            do{
                let value = try pwKeyChain.getString("userPW")
                return value as AnyObject?
            }catch{
                return nil
            }
        }
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

