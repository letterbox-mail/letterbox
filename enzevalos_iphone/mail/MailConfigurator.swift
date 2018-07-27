//
//  MailConfigurator.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 26.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class MailConfigurator {
    
    // Begin static stuff
    
    private static let SMTPPORT: [UInt32] = [587, 465, 25]
    private static let SMTPPREFIX = ["smtp", "mail", "outgoing"]
    
    private static let IMAPPREFIX = ["mail", "imap"]
    private static let IMAPPORT: [UInt32] = [143, 993]
    
    private static let AUTHTYPE = [MCOAuthType.saslLogin, MCOAuthType.SASLNTLM, MCOAuthType.saslKerberosV4, MCOAuthType.SASLCRAMMD5, MCOAuthType.SASLDIGESTMD5, MCOAuthType.SASLGSSAPI, MCOAuthType.SASLSRP, MCOAuthType.saslPlain]
    private static let CONNTECTIONTYPE = [MCOConnectionType.TLS, MCOConnectionType.startTLS] // We do not test for plain connections!
    
    static func defaultIMAP(userAddr: String) -> (hostname: String, port: UInt32, authType: MCOAuthType, connType: MCOConnectionType) {
        //TODO: Optimize here: Use files?
        let tokens = userAddr.split(separator: "@", maxSplits: 1)
        var hostname = "example.com"
        if tokens.count == 2 {
            hostname = String(tokens[1])
        }
        return (IMAPPREFIX[0]+"."+hostname, IMAPPORT[0], AUTHTYPE[0], CONNTECTIONTYPE[0])
    }
    
    static func defaultSMTP(userAddr: String) -> (hostname: String, port: UInt32, authType: MCOAuthType, connType: MCOConnectionType) {
        //TODO: Optimize here: Use files?
        
        return (SMTPPREFIX[0]+"."+MailConfigurator.hostname(userAddr: userAddr), SMTPPORT[0], AUTHTYPE[1], CONNTECTIONTYPE[0])
    }
    
    private static func hostname(userAddr: String) -> String {
        let tokens = userAddr.split(separator: "@", maxSplits: 1)
        var hostname = "example.com"
        if tokens.count == 2 {
            hostname = String(tokens[1])
        }
        return hostname
    }
    
    private static func findPreConfig(userAddr: String) -> MCOMailProvider?{
        let manager = MCOMailProvidersManager.shared()!
        let path = Bundle.main.path(forResource: "providers", ofType: "json")
        manager.registerProviders(withFilename: path)
        return manager.provider(forEmail: userAddr)
    }
    
    private static func fromFile(useraddr: String, password: String) -> MCOIMAPSession? {
        if let provider = MailConfigurator.findPreConfig(userAddr: useraddr) {
            if provider.imapServices().count > 0, let services = provider.imapServices() as? [MCONetService]{
                let imapService = services[0]
                return MailConfigurator.createIMAPSession(hostname: imapService.hostname, port: imapService.port, username: useraddr, password: password, authType: MailConfigurator.authType(service: imapService) , contype: imapService.connectionType)
            }
        }
        return nil
    }
    
    private static func fromFileSMTP(useraddr: String, password: String) -> MCOSMTPSession? {
        if let provider = MailConfigurator.findPreConfig(userAddr: useraddr) {
            if provider.smtpServices().count > 0, let services = provider.smtpServices() as? [MCONetService] {
                let smtpService = services[0]
                return MailConfigurator.createSMTPSession(hostname: smtpService.hostname, port: smtpService.port, username: useraddr, password: password, authType: MailConfigurator.authType(service: smtpService), contype: smtpService.connectionType)
            }
        }
        return nil
    }
    
    private static func authType(service: MCONetService) -> MCOAuthType {
        if let auth = service.info()["auth"] as? String {
            switch auth {
            case "saslPlain":
                return MCOAuthType.saslPlain
            case "saslLogin":
                return MCOAuthType.saslLogin
            case "saslKerberosV4":
                return MCOAuthType.saslKerberosV4
            case "saslCRAMMD5":
                return MCOAuthType.SASLCRAMMD5
            case "saslDIGESTMD5":
                return MCOAuthType.SASLDIGESTMD5
            case "saslGSSAPI":
                return MCOAuthType.SASLGSSAPI
            case "saslSRP":
                return MCOAuthType.SASLSRP
            case "saslNTLM":
                return MCOAuthType.SASLNTLM
            case "xoAuth2":
                return MCOAuthType.xoAuth2
            case "xoAuth2Outlook":
                return MCOAuthType.xoAuth2Outlook
            default:
                return MCOAuthType.saslPlain
            }
        }
        return MCOAuthType.saslPlain
    }
    
    private static func createSMTPSession (hostname: String, port: UInt32,  username: String, password: String?, authType: MCOAuthType, contype: MCOConnectionType) -> MCOSMTPSession {
        let session = MCOSMTPSession()
        session.hostname = hostname
        session.port = port
        session.username = username
        session.authType = authType
        if authType == MCOAuthType.xoAuth2 {
            if let lastToken = EmailHelper.singleton().authorization?.authState.lastTokenResponse {
                session.oAuth2Token = lastToken.accessToken
            }
        } else if let password = password {
            session.password = password
        }
        session.connectionType = contype
        return session
    }
    
    private static func createIMAPSession (hostname: String, port: UInt32,  username: String, password: String?, authType: MCOAuthType, contype: MCOConnectionType) -> MCOIMAPSession {
        let session = MCOIMAPSession()
        session.hostname = hostname
        session.port = port
        session.username = username
        session.authType = authType
        if authType == MCOAuthType.xoAuth2 {
            if let lastToken = EmailHelper.singleton().authorization?.authState.lastTokenResponse {
                session.oAuth2Token = lastToken.accessToken
            }
        } else if let password = password {
            session.password = password
        }
        session.connectionType = contype
        return session
    }
    
    // End static stuff
    
    var imapSession: MCOIMAPSession
    var smtpSession: MCOSMTPSession
    var userAddr: String
    var password: String
    
    private var considerIMAPFromFile = false
    private var considerSmtpFromFile = false
    
    init(imapSession: MCOIMAPSession, smtpSession: MCOSMTPSession, userAddr: String, password: String) {
        self.imapSession = imapSession
        self.smtpSession = smtpSession
        self.userAddr = userAddr
        self.password = password
    }
    
    convenience init(useraddr: String, password: String) {
        var imap: MCOIMAPSession
        var smtp: MCOSMTPSession
        var imapFile = false
        var smtpFile = false
        
        if let session = MailConfigurator.fromFile(useraddr: useraddr, password: password) {
            imap = session
            imapFile = true
        }
        else {
            let defaultIMAP = MailConfigurator.defaultIMAP(userAddr: useraddr)
            imap = MailConfigurator.createIMAPSession(hostname: defaultIMAP.hostname, port: defaultIMAP.port, username: useraddr, password: password, authType: defaultIMAP.authType, contype: defaultIMAP.connType)
        }
        
        if let session = MailConfigurator.fromFileSMTP(useraddr: useraddr, password: password){
            smtp = session
            smtpFile = true
        }
        else {
            let defaultSMTP = MailConfigurator.defaultSMTP(userAddr: useraddr)
            smtp = MailConfigurator.createSMTPSession(hostname: defaultSMTP.hostname, port: defaultSMTP.port, username: useraddr, password: password, authType: defaultSMTP.authType, contype: defaultSMTP.connType)
        }
        self.init(imapSession: imap, smtpSession: smtp, userAddr: useraddr, password: password)
        considerIMAPFromFile = imapFile
        considerSmtpFromFile = smtpFile
    }
    
    
    convenience init(userAddr: String, password: String, imapHostname: String, imapPort: UInt32, imapAuthType: MCOAuthType, imapConType: MCOConnectionType, smtpHostname: String, smtpPort: UInt32, smtpAuthType: MCOAuthType, smtpConType: MCOConnectionType) {
        let imap = MailConfigurator.createIMAPSession(hostname: imapHostname, port: imapPort, username: userAddr, password: password, authType: imapAuthType, contype: imapConType)
        let smtp = MailConfigurator.createSMTPSession(hostname: smtpHostname, port: smtpPort, username: userAddr, password: password, authType: smtpAuthType, contype: smtpConType)
        self.init(imapSession: imap, smtpSession: smtp, userAddr: userAddr, password: password)
    }
    
    
    
    
    func checkSettings(_ callback: @escaping (_ working: Bool) -> ()){
        checkIMAP({ (errorIMAP: Error?) -> () in
            if errorIMAP != nil {
                callback(false)
                return
            }
            self.checkSMTP({ (errorSMTP: Error?) -> () in
                if errorSMTP != nil {
                    callback(false)
                    return
                }
                callback(true)
                return
            })
        })
    }
    
    func findUserConfiguration(_ callback: @escaping (_ working: Bool) -> ()){
        findIMAPConfig({(working: Bool) -> () in
            if working {
                self.findSMTPConfig(callback)
            }
            else {
                callback(false)
            }
        })
    }
    
    func storeConfig(){
        UserManager.storeUser(mailAddr: userAddr, password: password)
        UserManager.storeServerConfig(type: ProtocolType.IMAP, server: imapSession.hostname, port: imapSession.port, authType: imapSession.authType.rawValue, connectionType: imapSession.connectionType.rawValue)
        UserManager.storeServerConfig(type: .SMTP, server: smtpSession.hostname, port: smtpSession.port, authType: smtpSession.authType.rawValue, connectionType: smtpSession.connectionType.rawValue)
    }
    
    private func findIMAPConfig(_ callback: @escaping (_ successful: Bool) -> ()){
        checkIMAP({(error: Error?) -> () in
            if error == nil {
                callback(true)
                return
            }
            if !self.considerIMAPFromFile {
                if let session = MailConfigurator.fromFile(useraddr: self.userAddr, password: self.password) {
                    self.imapSession = session
                    // recall with a new imap configuration from the default file
                    self.findIMAPConfig(callback)
                    self.considerIMAPFromFile = true
                    return
                }
            }
            self.iterateIMAPConfig(callback)
        })
    }
    
    private func findSMTPConfig(_ callback: @escaping (_ successful: Bool) -> ()){
        checkSMTP({(error: Error?) -> () in
            if error == nil {
                callback(true)
                return
            }
            if !self.considerSmtpFromFile {
                if let session = MailConfigurator.fromFileSMTP(useraddr: self.userAddr, password: self.password) {
                    self.smtpSession = session
                    self.findSMTPConfig(callback)
                    self.considerSmtpFromFile = true
                    return
                }
            }
            self.iterateSMTPConfig(callback)
        })
    }
    
    private func iterateConfig(_ callback: @escaping (_ working: Bool) -> (), prefixes: [String], ports: [UInt32], imap: Bool){
        let dispatchQueue = DispatchQueue(label: "ConfigChecker")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        let domain = MailConfigurator.hostname(userAddr: self.userAddr)
        let from = MCOAddress.init(mailbox: self.userAddr)
        dispatchQueue.async {
            for auth in MailConfigurator.AUTHTYPE {
                for conn in MailConfigurator.CONNTECTIONTYPE {
                    for port in ports{
                        for prefix in prefixes{
                            let hostname = prefix + "." + domain
                            if imap {
                                let session = MailConfigurator.createIMAPSession(hostname: hostname, port: port, username: self.userAddr, password: self.password, authType: auth, contype: conn)
                                session.checkAccountOperation().start({(error: Error?) -> () in
                                    if error == nil {
                                        self.imapSession = session
                                        callback(true)
                                        return
                                    }
                                    dispatchSemaphore.signal()
                                })
                            }
                            else {
                                let session = MailConfigurator.createSMTPSession(hostname: hostname, port: port, username: self.userAddr, password: self.password, authType: auth, contype: conn)
                                session.checkAccountOperationWith(from: from).start({(error: Error?) -> () in
                                    if error == nil {
                                        self.smtpSession = session
                                        callback(true)
                                        return
                                    }
                                    dispatchSemaphore.signal()
                                })
                            }
                            dispatchSemaphore.wait()
                        }
                    }
                }
            }
            callback(false)
            return
        }
    }
    
    private func iterateIMAPConfig(_ callback: @escaping (_ working: Bool) -> ()){
        iterateConfig(callback, prefixes: MailConfigurator.IMAPPREFIX, ports: MailConfigurator.IMAPPORT, imap: true)
    }
    
    private func iterateSMTPConfig(_ callback: @escaping (_ working: Bool) -> ()){
        iterateConfig(callback, prefixes: MailConfigurator.SMTPPREFIX, ports: MailConfigurator.SMTPPORT, imap: false)
    }
    
    private func completeOptionalInput(error: Error?) {
        if error != nil {
           // 2. Test user data
        }
        else {
            // store data
        }
    }
    
   
    private func checkIMAP(_ completion: @escaping (Error?) -> ()) {
       imapSession.checkAccountOperation().start(completion)
    }
    
    private func checkSMTP(_ completion: @escaping (Error?) -> ()) {
        smtpSession.checkAccountOperationWith(from: MCOAddress.init(mailbox: userAddr)).start(completion)
    }

    
   
}
