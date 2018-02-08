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

let invitationEnabled = false

let SUPPORT_MAIL_ADR = "letterbox@inf.fu-berlin.de"
let LOGGING_MAIL_ADR = "letterbox-reports@inf.fu-berlin.de"

func setupStudyPublicKeys(studyMode: Bool){
    if studyMode{
        let logging_pk = "logging_pk"
        let support_pk = "support_pk"
        let keys = ["noreply@bitcoin.de": "bitcoinde", "letterbox@zedat.fu-berlin.de": support_pk, SUPPORT_MAIL_ADR: support_pk, "letterbox-hilfe@inf.fu-berlin.de": support_pk, "enzevalos@inf.fu-berlin.de": support_pk, LOGGING_MAIL_ADR: logging_pk]
        importPublicKeyDic(keys: keys, type: "asc")
        let l = datahandler.getContact(name: "Letterbox", address: SUPPORT_MAIL_ADR, key: "F3ADDC8B81F82CCEB534CFC766BA7478AD254666", prefer_enc: true)
        datahandler.save(during: "init study keys")
    }
}

func loadTestAcc(){
   //loadBobEnzevalos()
    //loadAlice2005()
    //loadCharlieEnzevalos()
    //importPublicKeys()
    //loadBob2005()

    
}

func loadUlli(){
    let user =  web(name: "ullimuelle", pw: "dun3bate")
    userdefaults(defaults: user)
    importSecretKey(file: "ullimuelle-private", type: "gpg")
  
}

func loadBob2005(){
    let user = web(name: "bob2005", pw: "WJ$CE:EtUo3E$")
    userdefaults(defaults: user)
    importSecretKey(file: "bob2005-private", type: "gpg")
}

func loadAlice2005(){
    let user = web(name: "alice2005", pw: "WJ$CE:EtUo3E$")
    userdefaults(defaults: user)
    importSecretKey(file: "alice2005-private", type: "gpg")
  
}

func loadBobEnzevalos(){
    let user = enzevalos(name: "bob", pw: "VagotOshaicceov")
    userdefaults(defaults: user)
    importSecretKey(file: "bob_enzvalos_private", type: "asc")
}


func loadCharlieEnzevalos(){
    let user = enzevalos(name: "charlie", pw: "tydpawdAwIdPyuc")
    userdefaults(defaults: user)
}

// Enzevalos!
// static let name = "bob"
// static let pw = "VagotOshaicceov"
// static let name = "alice"
//static let pw = "egOavOpeecOntew"
//static let name = "charlie"
//static let pw = "tydpawdAwIdPyuc"

private func userdefaults(defaults: [Attribute: AnyObject?]){
    for (att, value) in defaults{
        UserManager.storeUserValue(value, attribute: att)
    }

}

private func web(name: String, pw: String) -> [Attribute: AnyObject?]{
    return  [.accountname : name as AnyObject?, .userName : name as Optional<AnyObject>, .userAddr : name+"@web.de" as Optional<AnyObject>, .userPW : pw as Optional<AnyObject>, .smtpHostname : "smtp.web.de" as Optional<AnyObject>, .smtpPort : 587 as Optional<AnyObject>,  .smtpConnectionType:MCOConnectionType.startTLS.rawValue as AnyObject?, .smtpAuthType:MCOAuthType.saslPlain.rawValue as AnyObject?, .imapHostname : "imap.web.de" as Optional<AnyObject>, .imapPort : 993 as AnyObject?, .imapConnectionType: MCOConnectionType.TLS.rawValue as AnyObject?,.imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?]
}

private func enzevalos(name: String, pw: String)-> [Attribute: AnyObject?]{
    return  [.accountname : name as AnyObject?, .userName : name as Optional<AnyObject>, .userAddr : name+"@enzevalos.de" as Optional<AnyObject>, .userPW : pw as Optional<AnyObject>, .smtpHostname : "mail.enzevalos.de" as Optional<AnyObject>, .smtpPort : 465 as Optional<AnyObject>, .smtpConnectionType: MCOConnectionType.TLS.rawValue as AnyObject? ,.smtpAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?,.imapHostname : "mail.enzevalos.de" as Optional<AnyObject>, .imapPort : 993 as AnyObject?, .imapConnectionType:MCOConnectionType.TLS.rawValue as AnyObject?, .imapAuthType: MCOAuthType.saslPlain.rawValue as AnyObject?]
}


func importPublicKeys(){
    let asc = ["jakob.bode@fu-berlin.de":"JakobBode", "alice@enzevalos.de":"alice_enzevalos_public", "bob@enzevalos.de":"bob_enzevalos_public", "dave@enzevalos.de":"dave_enzevalos_public"]
    let gpg = ["bob2005@web.de":"bob-public", "ullimuelle@web.de":"ullimuelle-public", "alice2005@web.de":"alice2005-public"]
    importPublicKeyDic(keys: asc, type: "asc")
    importPublicKeyDic(keys: gpg, type: "gpg")
  
}

func importSecretKey(file: String, type: String){
    if let path = Bundle.main.path(forResource: file, ofType: type){
        let ids = try! pgp.importKeysFromFile(file: path, pw: nil)
        for id in ids{
            _ = datahandler.newSecretKey(keyID: id)
        }
    }
}

private func importPublicKeyDic(keys: [String:String], type: String){
    for (adr, file) in keys{
        importPublicKey(file: file, type: type, adr: adr)
    }
}

private func importPublicKey(file: String, type: String, adr: String){
    if let path = Bundle.main.path(forResource: file, ofType: type){
        do{
            let ids = try pgp.importKeysFromFile(file: path, pw: nil)
            for id in ids{
                let k = datahandler.newPublicKey(keyID: id, cryptoType: CryptoScheme.PGP, adr: adr, autocrypt: false)
                print("New public key of \(adr) with id \(k.keyID)")
            }
        } catch _ {
            
        }
    }
}
