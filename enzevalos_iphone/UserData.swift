//
//  UserData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 20/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import KeychainAccess


enum Attribute: Int {
    case accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType, imapConnectionType, imapAuthType, smtpConnectionType, smtpAuthType, sentFolderPath, draftFolderPath, trashFolderPath, inboxFolderPath, archiveFolderPath, nextDeadline/*used for Logging; determines the earliest next time a log is send to the researchers*/, prefSecretKeyID, subjectSalt /*used for Logging; salt for the hashfunction for mail subjects*/, loggingFolderPath

    var defaultValue: AnyObject? {
        switch self {
        case .prefEncryption:
            return "mutal" as AnyObject?
        case .autocryptType:
            return "1" as AnyObject? // only openpgp
        case .sentFolderPath: //save backendFolderPath here
            return NSLocalizedString("Sent", comment: "Default name for the sentFolder; in UTF-7 as used in the backend") as AnyObject?
        case .draftFolderPath: //save backendFolderPath here
            return NSLocalizedString("Drafts", comment: "Default name for the draftFolder; in UTF-7 as used in the backend") as AnyObject?
        case .trashFolderPath: //save backendFolderPath here
            return NSLocalizedString("Trash", comment: "Default name for the trashFolder; in UTF-7 as used in the backend") as AnyObject?
        case .inboxFolderPath: //save backendFolderPath here
            return NSLocalizedString("INBOX", comment: "Default name for the inboxFolder; in UTF-7 as used in the backend") as AnyObject?
        case .archiveFolderPath: //save backendFolderPath here
            return NSLocalizedString("Archive", comment: "Default name for the archiveFolder; in UTF-7 as used in the backend") as AnyObject?
        case .nextDeadline: //save backendFolderPath here
            return Date(timeIntervalSinceNow: TimeInterval(Logger.loggingInterval)) as AnyObject?
        case .loggingFolderPath: //save backendFolderPath here
            return "letterbox-study" as AnyObject?
        default:
            return nil
        }
    }

    static let allAttributes = [accountname, userName, userAddr, userPW, smtpHostname, smtpPort, imapHostname, imapPort, prefEncryption, publicKey, autocryptType]
}


struct UserManager {

    private static var pwKeyChain: Keychain {
        get {
            return Keychain(service: "Enzevalos/Password")
        }
    }

    //Frontend (GUI and providers.json) uses UTF-8 String-Encoding
    //The backend uses because of the definition of IMAP UTF-7 String-Encoding
    static var frontendDraftFolderPath: String {
        get {
            return convertToFrontendFolderPath(from: backendDraftFolderPath)
        }
    }

    static var frontendInboxFolderPath: String {
        get {
            return convertToFrontendFolderPath(from: backendInboxFolderPath)
        }
    }

    static var frontendSentFolderPath: String {
        get {
            return convertToFrontendFolderPath(from: backendSentFolderPath)
        }
    }

    static var frontendArchiveFolderPath: String {
        get {
            return convertToFrontendFolderPath(from: backendArchiveFolderPath)
        }
    }

    static var frontendTrashFolderPath: String {
        get {
            return convertToFrontendFolderPath(from: backendTrashFolderPath)
        }
    }

    static var backendDraftFolderPath: String {
        get {
            return loadUserValue(.draftFolderPath) as? String ?? NSLocalizedString("Drafts", comment: "Default name for the draftFolder; in UTF-7 as used in the backend")
        }
    }

    static var backendSentFolderPath: String {
        get {
            return loadUserValue(.sentFolderPath) as? String ?? NSLocalizedString("Sent", comment: "Default name for the sentFolder; in UTF-7 as used in the backend")
        }
    }

    static var backendArchiveFolderPath: String {
        get {
            return loadUserValue(.archiveFolderPath) as? String ?? NSLocalizedString("Archive", comment: "Default name for the archiveFolder; in UTF-7 as used in the backend")
        }
    }

    static var backendTrashFolderPath: String {
        get {
            return loadUserValue(.trashFolderPath) as? String ?? NSLocalizedString("Trash", comment: "Default name for the trashFolder; in UTF-7 as used in the backend")
        }
    }

    static var backendInboxFolderPath: String {
        get {
            return loadUserValue(.inboxFolderPath) as? String ?? NSLocalizedString("INBOX", comment: "Default name for the inboxFolder; in UTF-7 as used in the backend")
        }
    }

    //Usable for paths too
    static func convertToFrontendFolderPath(from backendFolderPath: String, with delimiter: String = ".") -> String {
        if let mcoConverted = (AppDelegate.getAppDelegate().mailHandler.IMAPSession.defaultNamespace?.components(fromPath: backendFolderPath) as? [String])?.joined(separator: delimiter) {
            if backendFolderPath != mcoConverted && UserDefaults.standard.string(forKey: backendFolderPath) != mcoConverted {
                UserDefaults.standard.set(mcoConverted, forKey: backendFolderPath)
                UserDefaults.standard.set(backendFolderPath, forKey: mcoConverted)
            }
            return mcoConverted
        } else {
            if let cached = UserDefaults.standard.string(forKey: backendFolderPath) {
                return cached
            }
            return backendFolderPath
        }
    }

    //Usable for paths too
    static func convertToBackendFolderPath(from frontendFolderPath: String) -> String {
        if let mcoConverted = AppDelegate.getAppDelegate().mailHandler.IMAPSession.defaultNamespace?.path(forComponents: [frontendFolderPath]) {
            if frontendFolderPath != mcoConverted && UserDefaults.standard.string(forKey: frontendFolderPath) != mcoConverted {
                UserDefaults.standard.set(mcoConverted, forKey: frontendFolderPath)
                UserDefaults.standard.set(frontendFolderPath, forKey: mcoConverted)
            }
            return mcoConverted
        } else {
            if let cached = UserDefaults.standard.string(forKey: frontendFolderPath) {
                return cached
            }
            return frontendFolderPath
        }
    }

    static func storeUserValue(_ value: AnyObject?, attribute: Attribute) {
        if attribute == Attribute.userPW {
            let pw = value as! String
            pwKeyChain["userPW"] = pw
        } else {
            UserDefaults.standard.set(value, forKey: "\(attribute.rawValue)")
        }
    }

    static func loadUserValue(_ attribute: Attribute) -> AnyObject? {
        if attribute == Attribute.userPW {
            do {
                let value = try pwKeyChain.getString("userPW")
                return value as AnyObject?
            } catch {
                return nil
            }
        }
        let value = UserDefaults.standard.value(forKey: "\(attribute.rawValue)")
        if value != nil {
            return value as AnyObject?
        } else {
            _ = storeUserValue(attribute.defaultValue, attribute: attribute)
            return attribute.defaultValue
        }
    }

    static func loadImapAuthType() -> MCOAuthType{
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

    static func loadUserSignature() -> String {
        if UserDefaults.standard.bool(forKey: "Signature.Switch"), let sig = UserDefaults.standard.string(forKey: "Signature.Text") {
                return "\n\n______________________________\n\n\(sig.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        }

        return ""
    }
    
    static func loadInvitationMode()-> InvitationMode{
        let mode = UserDefaults.standard.integer(forKey: "Invitation.Mode")
        if let invitationmode = InvitationMode(rawValue: mode){
            return invitationmode
        }
        return InvitationMode.Censorship
    }

    static func resetUserValues() {
        for a in Attribute.allAttributes {
            storeUserValue(a.defaultValue, attribute: a)
            //UserDefaults.standard.removeObject(forKey: "\(a.hashValue)")
        }
    }
}

