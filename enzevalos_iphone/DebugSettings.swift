//
//  DebugSettings.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 28.09.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

let pgp = SwiftPGP()
let datahandler = DataHandler.handler

func loadTestAcc(){
    loadBobEnzevalos()
    //loadAlice2005()
    //loadCharlieEnzevalos()
    //importPublicKeys()

    
}

func loadUlli(){
    let user =  web(name: "ullimuelle", pw: "dun3bate")
    userdefaults(defaults: user)
    importSecretKey(file: "ullimuelle-private", type: "gpg")
  
}

func loadBob2005(){
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
    let asc = ["JakobBode":"jakob.bode@fu-berlin.de", "alice_enzevalos_public":"alice@enzevalos.de", "bob_enzevalos_public":"bob@enzevalos.de", "dave_enzevalos_public":"dave@enzevalos.de"]
    let gpg = ["idsolutions-public": "idsolutions@enzevalos.de", "nchr-public":"nchr@enzevalos.de", "ncpayroll-public":"ncpayroll@enzevalos.de", "bob-public":"bob2005@web.de", "ullimuelle-public": "ullimuelle@web.de", "alice2005-public":"alice2005@web.de"]
    importPublicKeyDic(keys: asc, type: "asc")
    importPublicKeyDic(keys: gpg, type: "gpg")
  
}

func importSecretKey(file: String, type: String){
    //TODO Remove old keys!
    if let path = Bundle.main.path(forResource: file, ofType: type){
        let ids = pgp.importKeysFromFile(file: path)
        for id in ids{
            let k = datahandler.newSecretKey(keyID: id)
            print("New secret key of \(file) with id \(String(describing: k.keyID))")
        }
    }
}


private func importPublicKeyDic(keys: [String:String], type: String){
    for (file, adr) in keys{
        importPublicKey(file: file, type: type, adr: adr)
    }
}

private func importPublicKey(file: String, type: String, adr: String){
    if let path = Bundle.main.path(forResource: file, ofType: type){
        let ids = pgp.importKeysFromFile(file: path)
        for id in ids{
            let k = datahandler.newPublicKey(keyID: id, cryptoType: CryptoScheme.PGP, adr: adr, autocrypt: false)
            print("New public key of \(adr) with id \(k.keyID)")
        }
    }
}
