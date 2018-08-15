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
    
    private var mailconfig: MailConfigurator?
    
    fileprivate init() { }
    
    static var handler: OnboardingDataHandler {
        get {
            if let handler = singleton {
                return handler
            }
            singleton = OnboardingDataHandler()
            return singleton!
        }
    }
    
    func setSettings(mailaddress: String, password: String) {
        if let mailconfig = mailconfig {
            mailconfig.userAddr = mailaddress
            mailconfig.password = password
        }
        else {
            mailconfig = MailConfigurator(userAddr: mailaddress, password: password)
        }
    }
    
    
    
    func setSettings(with mailaddress: String, password: String, username: String, imapServer: String, imapPort: Int, imapConnectionType: Int, imapAuthenticationType: Int, smtpServer: String, smtpPort: Int, smtpConnectionType: Int, smtpAuthenticationType: Int) {
        if let mailconfig = mailconfig {
            //TODO: Update mailconfig
            print("update Mail cpnfig!")
        }
        else {
            
            
            let imapAuth = MCOAuthType.init(rawValue: imapAuthenticationType % authenticationOptions.count)
            let imapCon = MCOConnectionType.init(rawValue: imapConnectionType % transportOptions.count)
            let smtpAuth = MCOAuthType.init(rawValue: smtpAuthenticationType % authenticationOptions.count)
            let smtpCon = MCOConnectionType.init(rawValue: smtpConnectionType % transportOptions.count)

            mailconfig = MailConfigurator(userAddr: mailaddress, password: password, accountName: nil, displayName: nil, imapHostname: imapServer, imapPort: UInt32(imapPort), imapAuthType: imapAuth  , imapConType: imapCon, smtpHostname: smtpServer, smtpPort: UInt32(smtpPort), smtpAuthType: smtpAuth, smtpConType: smtpCon)
        }
    }

    
    func checkSettings(callback: @escaping ((_ working: Bool) -> ())) {
        if let mailconfig = mailconfig {
            mailconfig.findUserConfiguration(true, callback)
        }
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
