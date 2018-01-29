//
//  LogInTests.swift
//  enzevalos_iphoneTests
//
//  Created by Oliver Wiese on 26.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//
import XCTest

@testable import enzevalos_iphone

class LogInTests: XCTestCase {
    
    
    
    private let pgp = SwiftPGP()
    private let datahandler = DataHandler.handler
    
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
    
    
    
    func testWordsInString() {
        
        let string = "Diese App hat viele Vorteile"
        let firstStringRange = NSRange(location: 0, length: 5)
        let secondStringRange = NSRange(location: 7, length: 9)
        
        let firstResult = string.words(inRange: firstStringRange)
        let secondResult = string.words(inRange: secondStringRange)
        
        print(firstResult)
        XCTAssertEqual(firstResult.count, 1)
        XCTAssertEqual(firstResult.first?.word, "Diese")
        XCTAssertEqual(firstResult.first?.index, 0)
        
        print(secondResult)
        XCTAssertEqual(secondResult.count, 3)
        XCTAssertEqual(secondResult[0].word, "App")
        XCTAssertEqual(secondResult[1].word, "hat")
        XCTAssertEqual(secondResult[2].word, "viele")
        XCTAssertEqual(secondResult[0].index, 6)
        XCTAssertEqual(secondResult[1].index, 10)
        XCTAssertEqual(secondResult[2].index, 14)
    }
    
    func testEncryptAndDecryptStrings() {
        
        let texts = ["Kontonummer", "DE 12345 625636 23", "Alice und Bob", "@~> ™", "12207", "🤨", "🤨 ABC123"]
        let pgp = SwiftPGP()
        
		let encryption = pgp.symmetricEncrypt(textToEncrypt: texts, armored: true)
        
        XCTAssertEqual(encryption.chiphers.count, texts.count)
        XCTAssertEqual(encryption.password.count, 9)
        
        let decryption = pgp.symmetricDecrypt(chipherTexts: encryption.chiphers, password: encryption.password)
        
        XCTAssertEqual(decryption, texts)
    }
}
