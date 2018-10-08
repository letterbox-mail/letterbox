//
//  DebugSettings.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 28.09.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

private let pgp = SwiftPGP()
private let datahandler = DataHandler.handler


let SUPPORT_MAIL_ADR = "letterbox@inf.fu-berlin.de"
let LOGGING_MAIL_ADR = "letterbox-reports@inf.fu-berlin.de"

func setupStudyPublicKeys() {
    let logging_pk = "logging_pk"
    let support_pk = "support_pk"
    let keys = ["noreply@bitcoin.de": "bitcoinde", "letterbox@zedat.fu-berlin.de": support_pk, "letterbox-hilfe@inf.fu-berlin.de": support_pk, "enzevalos@inf.fu-berlin.de": support_pk, SUPPORT_MAIL_ADR: support_pk, LOGGING_MAIL_ADR: logging_pk]
    importPublicKeyDic(keys: keys, type: "asc")
    datahandler.save(during: "init study keys")
}


private func userdefaults(defaults: [Attribute: AnyObject?]){
    for (att, value) in defaults{
        UserManager.storeUserValue(value, attribute: att)
    }
}

private func web(name: String, pw: String) -> [Attribute: AnyObject?] {
    return [.accountname: name as AnyObject?, .userName: name as Optional<AnyObject>, .userAddr: name + "@web.de" as Optional<AnyObject>, .userPW: pw as Optional<AnyObject>, .smtpHostname: "smtp.web.de" as Optional<AnyObject>, .smtpPort: 587 as Optional<AnyObject>, .smtpConnectionType: MCOConnectionType.startTLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .imapHostname: "imap.web.de" as Optional<AnyObject>, .imapPort: 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?]
}

private func enzevalos(name: String, pw: String) -> [Attribute: AnyObject?] {
    return [.accountname: name as AnyObject?, .userName: name as Optional<AnyObject>, .userAddr: name + "@enzevalos.de" as Optional<AnyObject>, .userPW: pw as Optional<AnyObject>, .smtpHostname: "mail.enzevalos.de" as Optional<AnyObject>, .smtpPort: 465 as Optional<AnyObject>, .smtpConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?, .imapHostname: "mail.enzevalos.de" as Optional<AnyObject>, .imapPort: 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?]
}


func importSecretKey(file: String, type: String){
    if let path = Bundle.main.path(forResource: file, ofType: type){
        let ids = try! pgp.importKeysFromFile(file: path, pw: nil)
        for id in ids {
            _ = datahandler.newSecretKey(keyID: id, addPk: true)
        }
    }
}

private func importPublicKeyDic(keys: [String: String], type: String) {
    for (adr, file) in keys {
        importPublicKey(file: file, type: type, adr: adr)
    }
}

private func importPublicKey(file: String, type: String, adr: String) {
    if let path = Bundle.main.path(forResource: file, ofType: type) {
        do {
            let ids = try pgp.importKeysFromFile(file: path, pw: nil)
            for id in ids {
                _ = datahandler.newPublicKey(keyID: id, cryptoType: CryptoScheme.PGP, adr: adr, autocrypt: false)
            }
        } catch _ {

        }
    }
}
