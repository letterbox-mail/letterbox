//
//  OutgoingMail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27.10.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation
class OutgoingMail {
    private var pgpAddresses: [MCOAddress] = []
    private var plainAddresses: [MCOAddress] = []
    private let toEntrys: [MCOAddress]
    private let ccEntrys: [MCOAddress]
    private let bccEntrys: [MCOAddress]
    var username = UserManager.loadUserValue(Attribute.userName) as! String
    var useraddr = UserManager.loadUserValue(Attribute.userAddr) as! String
    var userMCO: MCOAddress {
        get {
            return MCOAddress.init(displayName: username, mailbox: useraddr)
        }
    }
    private var sk: SecretKey {
        get {
            return DataHandler.handler.prefSecretKey()
        }
    }
    private let subject: String
    private var textparts: Int
    private let textContent: String
    private var htmlContent: String? = nil
    var pgpData: Data {
        get {
            return createEncMailPartBuilder().data()
        }
    }
    
    var plainData: Data? {
        get {
            guard plainAddresses.count > 0  else {
                return nil
            }
            if loggingMail {
                return nil
            }
            return createPlainMailPartBuilder().data()
        }
    }
    private var cryptoObject: CryptoObject? = nil
    
    var sendEncryptedIfPossible: Bool = true
    var loggingMail: Bool = false
    var warningReact: Bool = false
    var inviteMail: Bool = false
    var onlySelfEnc: Bool = false
    
    private var isDraft: Bool = false
    
    fileprivate var exportSecretKey: Bool = false
    fileprivate var keyID: String?
    fileprivate var keyData: String?
    fileprivate var passcode: String?

    
    init(toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, textContent: String, htmlContent: String?, textparts: Int = 0) {
        self.toEntrys = OutgoingMail.mapToMCOAddresses(addr: toEntrys)
        self.ccEntrys = OutgoingMail.mapToMCOAddresses(addr: ccEntrys)
        self.bccEntrys = OutgoingMail.mapToMCOAddresses(addr: bccEntrys)
        self.subject = subject
        self.textContent = textContent
        self.htmlContent = htmlContent
        self.textparts = textparts
    }
    
    func logMail() -> Bool {
        guard Logger.logging && !loggingMail else {
            return false
        }
        // We don't log the logging mail
        if loggingMail {
            return false
        }
        let fromLogging: Mail_Address = DataHandler.handler.getMailAddress(useraddr, temporary: false) as! Mail_Address
        let toLogging: [Mail_Address] = []
        let ccLogging: [Mail_Address] = []
        let bccLogging: [Mail_Address] = []
        let secureAddrsInString = pgpAddresses.map { $0.mailbox }
        var secureAddresses: [Mail_Address] = []
        for addr in toLogging {
            for sec in secureAddrsInString {
                if addr.address == sec {
                    secureAddresses.append(addr)
                }
            }
        }
        for addr in ccLogging {
            for sec in secureAddrsInString {
                if addr.address == sec {
                    secureAddresses.append(addr)
                }
            }
        }
        for addr in bccLogging {
            for sec in secureAddrsInString {
                if addr.address == sec {
                    secureAddresses.append(addr)
                }
            }
        }
        var inviteMailContent: String? = nil
        if inviteMail {
            inviteMailContent = textparts.description
        }
        if let co = cryptoObject {
            let isEnc = co.encryptionState == EncryptionState.ValidedEncryptedWithCurrentKey || co.encryptionState == EncryptionState.ValidEncryptedWithOldKey || co.encryptionState == EncryptionState.UnableToDecrypt
            let isSig = co.signatureState == .ValidSignature || co.signatureState == .InvalidSignature || co.signatureState == .NoPublicKey
            let isCorSig = co.signatureState == .ValidSignature
            if isDraft {
                Logger.log(createDraft: toLogging, cc: ccLogging, bcc: bccLogging, subject: subject, bodyLength: textContent.count, isEncrypted: isEnc, isSigned: isSig, myKeyID: keyID ?? "")
            }
            else {
                Logger.log(sent: fromLogging, to: toLogging, cc: ccLogging, bcc: bccLogging, subject: subject, bodyLength: co.chiperString?.count ?? 0, isEncrypted: isEnc, decryptedBodyLength: ("\n" + (co.plaintext ?? "")).count, decryptedWithOldPrivateKey: false, isSigned: isSig, isCorrectlySigned: isCorSig, signingKeyID: co.signKey ?? "", myKeyID: sk.keyID ?? "", secureAddresses: secureAddresses, encryptedForKeyIDs: OutgoingMail.addKeys(adrs: pgpAddresses), inviteMailContent: inviteMailContent, invitationMail: inviteMail)
            }
        }
        else {
            if isDraft {
                Logger.log(createDraft: toLogging, cc: ccLogging, bcc: bccLogging, subject: subject, bodyLength: textContent.count, isEncrypted: false, isSigned: false, myKeyID: "")
            }
            else {
                Logger.log(sent: fromLogging, to: toLogging, cc: ccLogging, bcc: bccLogging, subject: subject, bodyLength: ("\n" + textContent).count, isEncrypted: false, decryptedBodyLength: ("\n" + textContent).count, decryptedWithOldPrivateKey: false, isSigned: false, isCorrectlySigned: false, signingKeyID: "", myKeyID: "", secureAddresses: [], encryptedForKeyIDs: [], inviteMailContent: inviteMailContent, invitationMail: inviteMail)
            }
        }
        return true
    }
    
   
    
    func createPlainMailPartBuilder() -> MCOMessageBuilder {
        let builder = createBuilder()
        if let html = htmlContent {
            builder.htmlBody = html
        } else {
            builder.textBody = textContent //Maybe add both?!
        }
        return builder
    }
    
    func createEncMailPartBuilder() -> MCOMessageBuilder {
        let encMailBuilder = createBuilder()
        let pgp = SwiftPGP()
        var msg = textContent
        var missingOwnPublic = false
        
        var pgpKeyIds: [String] = []
        pgpKeyIds.append(sk.keyID!)
        if !onlySelfEnc {
            pgpKeyIds.append(contentsOf: OutgoingMail.addKeys(adrs: pgpAddresses))
        }
        // We add our public if one uses pgp but may not our public key
        for id in pgpKeyIds {
            if let key = DataHandler.handler.findKey(keyID: id) {
                if !key.sentOwnPublicKey {
                    missingOwnPublic = true
                    key.sentOwnPublicKey = true
                }
            }
        }
        if missingOwnPublic {
            if let myPK = pgp.exportKey(id: sk.keyID!, isSecretkey: false, autocrypt: false) {
                msg = msg + "\n" + myPK //TODO: Append pgp.asc?
            }
        }
        cryptoObject = pgp.encrypt(plaintext: "\n" + msg, ids: pgpKeyIds, myId: sk.keyID!)
        if let encData = cryptoObject?.chiphertext {
            encMailBuilder.openPGPEncryptedMessageData(withEncryptedData: encData)
        }
        return encMailBuilder
    }
    
    private func orderReceiver(receivers: [String], sendEncryptedIfPossible: Bool){
        for r in receivers {
            let mco = MCOAddress(displayName: r, mailbox: r)
            if let adr = DataHandler.handler.findMailAddress(adr: r) {
                let recommandation = Autocrypt.recommandateEncryption(receiver: adr)
                if recommandation.recommandEnc {
                    pgpAddresses.append(mco!)
                }
                else {
                   plainAddresses.append(mco!)
                }
            } else {
                plainAddresses.append(mco!)
            }
        }
    }
    
    private func createBuilder() -> MCOMessageBuilder {
        let builder = MCOMessageBuilder()
        builder.header.to = toEntrys
        builder.header.cc = ccEntrys
        builder.header.bcc = bccEntrys
        builder.header.from = MCOAddress(displayName: username, mailbox: useraddr)
        builder.header.subject = subject
        builder.header.setExtraHeaderValue("letterbox", forName: "X-Mailer")
        Autocrypt.addAutocryptHeader(builder)
        
        if exportSecretKey {
            if let keyID = keyID, let keyData = keyData, let passcode = passcode {
                Autocrypt.createAutocryptKeyExport(builder: builder, keyID: keyID, key: keyData, passcode: passcode)
            }
        }
        return builder
    }
    
    private static func mapToMCOAddresses(addr: [String]) -> [MCOAddress] {
        return addr.map({(value: String) -> MCOAddress in
            return MCOAddress.init(mailbox: value)})
    }
    
    private static func addKeys(adrs: [MCOAddress]) -> [String] {
        var ids = [String]()
        for a in adrs {
            if let adr = DataHandler.handler.findMailAddress(adr: a.mailbox), let key = adr.primaryKey?.keyID {
                ids.append(key)
            }
        }
        return ids
    }
    
    static func createDraft (toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, textContent: String, htmlContent: String?) -> OutgoingMail{
        let mail = OutgoingMail(toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, textContent: textContent, htmlContent: htmlContent)
        mail.isDraft = true
        return mail
    }
    static func createInvitationMail(toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, textContent: String, htmlContent: String?) -> OutgoingMail{
        let mail = OutgoingMail(toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, textContent: textContent, htmlContent: htmlContent)
        mail.inviteMail = true
        return mail
    }
    static func createSecretKeyExportMail(keyID: String, keyData: String, passcode: String) -> OutgoingMail{
        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        let mail = OutgoingMail(toEntrys: [useraddr], ccEntrys: [], bccEntrys: [], subject: "Autocrypt Setup Message", textContent: "", htmlContent: nil)
        mail.exportSecretKey = true
        mail.keyData = keyData
        mail.keyID = keyID
        mail.passcode = passcode
        return mail
    }
    static func createLoggingMail(addr: String, textcontent: String) -> OutgoingMail{
            let mail = OutgoingMail(toEntrys: [addr], ccEntrys: [], bccEntrys: [], subject: "[Letterbox] Log", textContent: textcontent, htmlContent: nil)
            mail.loggingMail = true
            return mail
    }
}
