//
//  OnboardingDataHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 17.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingDataHandler {
    
    let authenticationOptions: [Int: String] = [MCOAuthType.saslLogin.rawValue: "Login", MCOAuthType.saslPlain.rawValue: NSLocalizedString("NormalPassword", comment: ""), MCOAuthType.SASLSRP.rawValue: "SRP", MCOAuthType.SASLCRAMMD5.rawValue: "CRAMMD5", MCOAuthType.SASLDIGESTMD5.rawValue: "DIGESTMD5", MCOAuthType.SASLNTLM.rawValue: "NTLM", MCOAuthType.SASLGSSAPI.rawValue: "GSSAPI", MCOAuthType.saslKerberosV4.rawValue: "KerberosV4", 0: "None"]
    let transportOptions: [Int: String] = [MCOConnectionType.clear.rawValue: NSLocalizedString("Plaintext", comment: ""), MCOConnectionType.startTLS.rawValue: "StartTLS", MCOConnectionType.TLS.rawValue: "TLS"]
    
    fileprivate static var singleton: OnboardingDataHandler?
    
    fileprivate func init() { }
    
    static var handler {
        get {
            if let handler = singleton {
                return handler
            }
            singleton = OnboardingDataHandler()
            return singleton
        }
    }
    
    func checkSettings(with mailaddress: String, password: String, callback: ((working: Bool) -> ())) {
        let mailAddress = (mailaddress.text ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var guessedUserName = ""
        if mailAddress.components(separatedBy: "@").count >= 1 {
            guessedUserName = mailAddress.components(separatedBy: "@")[0]
        }
        UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.userName)
        UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userAddr)
        UserManager.storeUserValue((password.text ?? "") as AnyObject?, attribute: Attribute.userPW)
        loadTestAcc()
        setServerValues(mailaddress: mailAddress)
        checkSettings(working)
    }
    
    func checkSettings(with mailaddress: String, password: String, username: String, imapServer: String, imapPort: Int, imapConnectionTypeIndex: Int, imapAuthenticationTypeIndex: Int, smtpServer: Sting, smtpPort: Int, smtpConnectionTypeIndex: Int, smtpAuthenticationTypeIndex: Int, callback: ((working: Bool) -> ())) {
        UserManager.storeUserValue(imapServer as AnyObject?, attribute: Attribute.imapHostname)
        UserManager.storeUserValue(imapPort as AnyObject?, attribute: Attribute.imapPort)
        UserManager.storeUserValue(smtpServer as AnyObject?, attribute: Attribute.smtpHostname)
        UserManager.storeUserValue(smtpPort as AnyObject?, attribute: Attribute.smtpPort)
        UserManager.storeUserValue(mailaddress as AnyObject?, attribute: Attribute.userAddr)
        UserManager.storeUserValue(password as AnyObject?, attribute: Attribute.userPW)
        UserManager.storeUserValue(username as AnyObject?, attribute: Attribute.userName)
        UserManager.storeUserValue(username as AnyObject?, attribute: Attribute.accountname)
        UserManager.storeUserValue(keyForValue(transportOptions, value: imapConnectionTypeIndex)[0] as AnyObject?, attribute: Attribute.imapConnectionType)
        UserManager.storeUserValue(keyForValue(authenticationOptions, value: imapAuthenticationTypeIndex)[0] as AnyObject?, attribute: Attribute.imapAuthType)
        UserManager.storeUserValue(keyForValue(transportOptions, value: smtpConnectionTypeIndex)[0] as AnyObject?, attribute: Attribute.smtpConnectionType)
        UserManager.storeUserValue(keyForValue(authenticationOptions, value: smtpAuthenticationTypeIndex)[0] as AnyObject?, attribute: Attribute.smtpAuthType)
        checkSettings(working)
    }
    
    fileprivate func checkSettings(callback: ((working: Bool) -> ())) {
        AppDelegate.getAppDelegate().mailHandler.checkIMAP({ (error: Error?) -> () in
            if error == nil {
                AppDelegate.getAppDelegate().mailHandler.checkSMTP({ (error2: Error?) -> () in
                    if error2 == nil {
                        callback(true)
                        return
                    }
                    callback(false)
                })
                return
            }
            callback(false)
            return
        })
    }
    
    fileprivate func setServerValues(mailaddress: String) {
        let manager = MCOMailProvidersManager.shared()!
        let path = Bundle.main.path(forResource: "providers", ofType: "json")
        manager.registerProviders(withFilename: path)
        
        if let provider = manager.provider(forEmail: mailaddress), let imap = (provider.imapServices() as? [MCONetService]), imap != [], let smtp = (provider.smtpServices() as? [MCONetService]), smtp != [] {
            let imapService = imap[0]
            UserManager.storeUserValue((imapService.info()["hostname"] ?? "imap.example.com") as AnyObject?, attribute: Attribute.imapHostname)
            UserManager.storeUserValue((imapService.info()["port"] ?? 587) as AnyObject?, attribute: Attribute.imapPort)
            
            if let trans = imapService.info()["ssl"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
            } else if let trans = imapService.info()["starttls"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
            } else {
                UserManager.storeUserValue(MCOConnectionType.clear.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
            }
            
            if let auth = imapService.info()["auth"] as? String, auth == "saslPlain" {
                UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslLogin" {
                UserManager.storeUserValue(MCOAuthType.saslLogin.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslKerberosV4" {
                UserManager.storeUserValue(MCOAuthType.saslKerberosV4.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslCRAMMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslDIGESTMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLDIGESTMD5.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslGSSAPI" {
                UserManager.storeUserValue(MCOAuthType.SASLGSSAPI.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslSRP" {
                UserManager.storeUserValue(MCOAuthType.SASLSRP.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslNTLM" {
                UserManager.storeUserValue(MCOAuthType.SASLNTLM.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "xoAuth2" {
                UserManager.storeUserValue(MCOAuthType.xoAuth2.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "xoAuth2Outlook" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else {
                UserManager.storeUserValue(0 as AnyObject?, attribute: Attribute.imapAuthType)
            }
            
            let smtpService = smtp[0]
            UserManager.storeUserValue((smtpService.info()["hostname"] ?? "smtp.example.com") as AnyObject?, attribute: Attribute.smtpHostname)
            UserManager.storeUserValue((smtpService.info()["port"] ?? 993) as AnyObject?, attribute: Attribute.smtpPort)
            
            if let trans = smtpService.info()["ssl"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
            } else if let trans = smtpService.info()["starttls"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
            } else {
                UserManager.storeUserValue(MCOConnectionType.clear.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
            }
            
            if let auth = smtpService.info()["auth"] as? String, auth == "saslPlain" {
                UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslLogin" {
                UserManager.storeUserValue(MCOAuthType.saslLogin.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslKerberosV4" {
                UserManager.storeUserValue(MCOAuthType.saslKerberosV4.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslCRAMMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslDIGESTMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLDIGESTMD5.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslGSSAPI" {
                UserManager.storeUserValue(MCOAuthType.SASLGSSAPI.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslSRP" {
                UserManager.storeUserValue(MCOAuthType.SASLSRP.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslNTLM" {
                UserManager.storeUserValue(MCOAuthType.SASLNTLM.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "xoAuth2" {
                UserManager.storeUserValue(MCOAuthType.xoAuth2.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "xoAuth2Outlook" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else {
                UserManager.storeUserValue(0 as AnyObject?, attribute: Attribute.smtpAuthType)
            }
            
            if let drafts = provider.draftsFolderPath() {
                UserManager.storeUserValue(drafts as AnyObject?, attribute: Attribute.draftFolderPath)
            }
            if let sent = provider.sentMailFolderPath() {
                UserManager.storeUserValue(sent as AnyObject?, attribute: Attribute.sentFolderPath)
            }
            if let trash = provider.trashFolderPath() {
                UserManager.storeUserValue(trash as AnyObject?, attribute: Attribute.trashFolderPath)
            }
            if let archive = provider.allMailFolderPath() {
                UserManager.storeUserValue(archive as AnyObject?, attribute: Attribute.archiveFolderPath)
            }
        }
        else {
            setDefaultValues()
        }
    }
    
    fileprivate func setDefaultValues() {
        UserManager.storeUserValue("imap.example.de" as AnyObject?, attribute: Attribute.imapHostname)
        UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
        UserManager.storeUserValue(993 as AnyObject?, attribute: Attribute.imapPort)
        UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
        UserManager.storeUserValue("smtp.example.de" as AnyObject?, attribute: Attribute.smtpHostname)
        UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
        UserManager.storeUserValue(587 as AnyObject?, attribute: Attribute.smtpPort)
        UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
    }
    
    //Inspired by http://stackoverflow.com/questions/32692450/swift-dictionary-get-key-for-values
    fileprivate func keyForValue(_ dict: [Int: String], value: String) -> [Int] {
        let keys = dict.filter {
            return $0.1 == value
            }.map {
                return $0.0
        }
        return keys
    }
}
