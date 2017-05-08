//
//  Providers.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 24.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

enum Provider : String {
    case WEB = "web.de", FU = "fu-berlin.de", ZEDAT = "zedat.fu-berlin.de", ENZEVALOS = "enzevalos.de"
}

class Providers {
    static let config: [Provider : [Attribute : AnyObject?]] = createConfig()

        /*Provider.WEB : [.smtpHostname : "smtp.web.de" as AnyObject?, .smtpPort : 587 as AnyObject?, .imapHostname : "imap.web.de" as AnyObject?, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?],
        Provider.FU : [.smtpHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .smtpPort : 587 as AnyObject?, .imapHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?],
        Provider.ZEDAT : [.smtpHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .smtpPort : 587 as AnyObject?, .imapHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .imapPort : 143 as AnyObject?, .imapConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?],
        Provider.ENZEVALOS : [.smtpHostname : "mail.enzevalos.de" as AnyObject?, .smtpPort : 465 as AnyObject?, .imapHostname : "mail.enzevalos.de" as AnyObject?, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?]*/
    
    static func createConfig() -> [Provider : [Attribute : AnyObject?]] {
        var config: [Provider : [Attribute : AnyObject?]] = [:]
        config.updateValue([.smtpHostname : "smtp.web.de" as AnyObject?, .smtpPort : 587 as AnyObject?, .imapHostname : "imap.web.de" as AnyObject?, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?], forKey: Provider.WEB)
        config.updateValue([.smtpHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .smtpPort : 587 as AnyObject?, .imapHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?], forKey: Provider.FU)
        config.updateValue([.smtpHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .smtpPort : 587 as AnyObject?, .imapHostname : "mail.zedat.fu-berlin.de" as AnyObject?, .imapPort : 143 as AnyObject?, .imapConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?], forKey: Provider.ZEDAT)
        config.updateValue([.smtpHostname : "mail.enzevalos.de" as AnyObject?, .smtpPort : 465 as AnyObject?, .imapHostname : "mail.enzevalos.de" as AnyObject?, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .smtpConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?], forKey: Provider.ENZEVALOS)
        return config
    }
    
    static func setValues(_ provider: Provider) {
        for key in (config[provider]?.keys)! {
            UserManager.storeUserValue(config[provider]![key]!, attribute: key)
        }
    }
}
