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
    static let config: [Provider : [Attribute : AnyObject?]] = [
        Provider.WEB : [.SMTPHostname : "smtp.web.de", .SMTPPort : 587, .IMAPHostname : "imap.web.de", .IMAPPort : 993, .ConnectionType: MCOConnectionType.StartTLS.rawValue, .AuthType: MCOAuthType.SASLPlain.rawValue],
        Provider.FU : [.SMTPHostname : "mail.zedat.fu-berlin.de", .SMTPPort : 587, .IMAPHostname : "mail.zedat.fu-berlin.de", .IMAPPort : 993, .ConnectionType: MCOConnectionType.TLS.rawValue, .AuthType: MCOAuthType.SASLPlain.rawValue],
        Provider.ZEDAT : [.SMTPHostname : "mail.zedat.fu-berlin.de", .SMTPPort : 587, .IMAPHostname : "mail.zedat.fu-berlin.de", .IMAPPort : 993, .ConnectionType: MCOConnectionType.TLS.rawValue, .AuthType: MCOAuthType.SASLLogin.rawValue],
        Provider.ENZEVALOS : [.SMTPHostname : "mail.enzevalos.de", .SMTPPort : 465, .IMAPHostname : "mail.enzevalos.de", .IMAPPort : 993, .ConnectionType: MCOConnectionType.TLS.rawValue, .AuthType: MCOAuthType.SASLLogin.rawValue]]
    
    static func setValues(provider: Provider) {
        for key in (config[provider]?.keys)! {
            UserManager.storeUserValue(config[provider]![key]!, attribute: key)
        }
    }
}
