 //
//  MailHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 22.08.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//




import Foundation
import Contacts
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}



let AUTOCRYPTHEADER = "Autocrypt"
let SETUPMESSAGE = "Autocrypt-Setup-Message"
let ADDR = "addr"
let TYPE = "type"
let ENCRYPTION = "prefer-encrypt"
let KEY = "keydata"


class AutocryptContact {
    var addr: String = ""
    var type: CryptoScheme = .PGP
    var prefer_encryption: EncState = EncState.NOAUTOCRYPT
    var key: String = ""

    init(addr: String, type: String, prefer_encryption: String, key: String) {
        self.addr = addr
        self.key = key
        setPrefer_encryption(prefer_encryption)
    }


    convenience init(header: MCOMessageHeader) {
        var autocrypt = header.extraHeaderValue(forName: AUTOCRYPTHEADER)
        var field: [String]
        var addr = ""
        var type = "1"
        var pref = "mutal"
        var key = ""

        if autocrypt != nil {
            autocrypt = autocrypt?.trimmingCharacters(in: .whitespacesAndNewlines)
            let autocrypt_fields = autocrypt?.components(separatedBy: ";")
            for f in autocrypt_fields! {
                field = f.components(separatedBy: "=")
                if field.count > 1 {
                    let flag = field[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    var value = field[1]
                    if field.count > 2 {
                        for i in 2...(field.count - 1) {
                            value = value + "="
                            value = value + field[i]
                        }
                    }
                    switch flag {
                    case ADDR:
                        addr = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        addr = addr.lowercased()
                        break
                    case TYPE:
                        type = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    case ENCRYPTION:
                        pref = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    case KEY:
                        if value.count > 0 {
                            key = value
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
        self.init(addr: addr, type: type, prefer_encryption: pref, key: key)
    }


    func setPrefer_encryption(_ input: String){
        let pref = input.lowercased()
        if pref == "yes" || pref == "mutal" {
            self.prefer_encryption = EncState.MUTAL
        } else if pref == "no" {
            self.prefer_encryption = EncState.NOPREFERENCE
        }
        prefer_encryption = EncState.NOPREFERENCE
    }

    func toString() -> String {
        return "Addr: \(addr) | type: \(type) | encryption? \(prefer_encryption) key size: \(key.count)"
    }
}

class MailHandler {

    var delegate: MailHandlerDelegator?

    var INBOX: String {
        return "INBOX"
    }

    fileprivate static let MAXMAILS = 25

    fileprivate let concurrentMailServer = DispatchQueue(label: "com.enzevalos.mailserverQueue", attributes: DispatchQueue.Attributes.concurrent)

    private var IMAPSes: MCOIMAPSession?

    var IMAPSession: MCOIMAPSession {
        if IMAPSes == nil {
            IMAPSes = setupIMAPSession()
        }
        return IMAPSes!
    }

    var IMAPIdleSession: MCOIMAPSession?
    var IMAPIdleSupported: Bool?

    var shouldTryRefreshOAUTH: Bool {
        return (UserManager.loadImapAuthType() == MCOAuthType.xoAuth2 || UserManager.loadSmtpAuthType() == MCOAuthType.xoAuth2) &&
            !(EmailHelper.singleton().authorization?.authState.isTokenFresh() ?? false)
    }

    private func addAutocryptHeader(_ builder: MCOMessageBuilder) {
        let adr = (UserManager.loadUserValue(Attribute.userAddr) as! String).lowercased()
        let skID = DataHandler.handler.prefSecretKey().keyID

        let pgp = SwiftPGP()
        if let id = skID {
            let enc = "yes"
            if let key = pgp.exportKey(id: id, isSecretkey: false, autocrypt: true) {
                var string = "\(ADDR)=" + adr
                if enc == "yes" {
                    string = string + "; \(ENCRYPTION)=mutal"
                }
                string = string + "; \(KEY)= \n" + key
                builder.header.setExtraHeaderValue(string, forName: AUTOCRYPTHEADER)
            }
        }
    }

    fileprivate func createHeader(_ builder: MCOMessageBuilder, toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String) {

        let username = UserManager.loadUserValue(Attribute.userName) as! String
        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)

        var toReady: [MCOAddress] = []
        for addr in toEntrys {
            toReady.append(MCOAddress(displayName: addr, mailbox: addr))
        }
        builder.header.to = toReady

        var ccReady: [MCOAddress] = []
        for addr in ccEntrys {
            ccReady.append(MCOAddress(displayName: addr, mailbox: addr))
        }
        builder.header.cc = ccReady

        var bccReady: [MCOAddress] = []
        for addr in bccEntrys {
            bccReady.append(MCOAddress(displayName: addr, mailbox: addr))
        }

        builder.header.bcc = bccReady
        builder.header.from = MCOAddress(displayName: username, mailbox: useraddr)
        builder.header.subject = subject
        builder.header.setExtraHeaderValue("letterbox", forName: "X-Mailer")

        addAutocryptHeader(builder)

    }

    private func orderReceiver(receiver: [String], sendEncryptedIfPossible: Bool) -> [CryptoScheme: [MCOAddress]] {
        var orderedReceiver = [CryptoScheme: [MCOAddress]]()
        orderedReceiver[CryptoScheme.PGP] = [MCOAddress]()
        orderedReceiver[CryptoScheme.UNKNOWN] = [MCOAddress]()

        for r in receiver {
            let mco = MCOAddress(displayName: r, mailbox: r)
            if let adr = DataHandler.handler.findMailAddress(adr: r), adr.hasKey, sendEncryptedIfPossible { // TODO: include encryption preference of Autocrypt
                orderedReceiver[CryptoScheme.PGP]?.append(mco!)
            } else {
                orderedReceiver[CryptoScheme.UNKNOWN]?.append(mco!)
            }
        }
        return orderedReceiver
    }

    private func addKeys(adrs: [MCOAddress]) -> [String] {
        var ids = [String]()
        for a in adrs {
            if let adr = DataHandler.handler.findMailAddress(adr: a.mailbox), let key = adr.primaryKey?.keyID {
                ids.append(key)
            }
        }
        return ids
    }

    func sendSecretKey(key: String, passcode: String, callback: @escaping (Error?) -> Void) {
        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        let session = createSMTPSession()
        let builder = MCOMessageBuilder()
        let userID: MCOAddress = MCOAddress(displayName: useraddr, mailbox: useraddr)

        createHeader(builder, toEntrys: [useraddr], ccEntrys: [], bccEntrys: [], subject: "Autocrypt Setup Message")
        builder.header.setExtraHeaderValue("v0", forName: SETUPMESSAGE)


        builder.addAttachment(MCOAttachment.init(text: "This message contains a secret for reading secure mails on other devices. \n 1) Input the passcode from your smartphone to unlock the message on your other device. \n 2) Import the secret key into your pgp program on the device.  \n\n For more information visit:https://userpage.fu-berlin.de/letterbox/faq.html#otherDevices \n\n"))

        // See: https://autocrypt.org/level1.html#autocrypt-setup-message
        let keyAttachment = MCOAttachment.init(text: key)
        builder.addAttachment(keyAttachment)

        let sendOperation = session.sendOperation(with: builder.data(), from: userID, recipients: [userID])
        sendOperation?.start({ error in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.sendSecretKey(key: key, passcode: passcode, callback: callback)}, completionCallback: nil)
                return
            }
            callback(nil)
        })
    }

    func send(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, sendEncryptedIfPossible: Bool = true, callback: @escaping (Error?) -> Void, loggingMail: Bool = false, htmlContent: String? = nil, warningReact: Bool = false, inviteMail: Bool = false, textparts: Int = 0) {
        if let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as? String) {
            let session = createSMTPSession()
            let builder = MCOMessageBuilder()

            createHeader(builder, toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject)

            var allRec: [String] = []
            allRec.append(contentsOf: toEntrys)
            allRec.append(contentsOf: ccEntrys)
            allRec.append(contentsOf: bccEntrys)

            let fromLogging: Mail_Address = DataHandler.handler.getMailAddress(useraddr, temporary: false) as! Mail_Address
            var toLogging: [Mail_Address] = []
            var ccLogging: [Mail_Address] = []
            var bccLogging: [Mail_Address] = []

            for entry in toEntrys {
                toLogging.append(DataHandler.handler.getMailAddress(entry, temporary: false) as! Mail_Address)
            }
            for entry in ccEntrys {
                ccLogging.append(DataHandler.handler.getMailAddress(entry, temporary: false) as! Mail_Address)
            }
            for entry in bccEntrys {
                bccLogging.append(DataHandler.handler.getMailAddress(entry, temporary: false) as! Mail_Address)
            }

            let ordered = orderReceiver(receiver: allRec, sendEncryptedIfPossible: sendEncryptedIfPossible)

            let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)
            let sk = DataHandler.handler.prefSecretKey()

            var sendData: Data
            var sendOperation: MCOSMTPSendOperation
            let pgp = SwiftPGP()

            if let encPGP = ordered[CryptoScheme.PGP], encPGP.count > 0 {
                var keyIDs = addKeys(adrs: encPGP)
                // added own public key here, so we can decrypt our own message to read it in sent-folder
                keyIDs.append(sk.keyID!)
                /*
                 Attach own public key
                */
                var missingOwnPublic = false
                for id in keyIDs {
                    if let key = DataHandler.handler.findKey(keyID: id) {
                        if !key.sentOwnPublicKey {
                            missingOwnPublic = true
                            key.sentOwnPublicKey = true
                        }
                    }
                }

                var msg = message
                if missingOwnPublic {
                    if let myPK = pgp.exportKey(id: sk.keyID!, isSecretkey: false, autocrypt: false) {
                        msg = msg + "\n" + myPK
                    }
                }

                let cryptoObject = pgp.encrypt(plaintext: "\n" + msg, ids: keyIDs, myId: sk.keyID!)
                if let encData = cryptoObject.chiphertext {
                    sendData = encData
                    if Logger.logging && !loggingMail {
                        let secureAddrsInString = encPGP.map { $0.mailbox }
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
                        Logger.log(sent: fromLogging, to: toLogging, cc: ccLogging, bcc: bccLogging, subject: subject, bodyLength: (String(data: cryptoObject.chiphertext!, encoding: String.Encoding.utf8) ?? "").count, isEncrypted: true, decryptedBodyLength: ("\n" + message).count, decryptedWithOldPrivateKey: false, isSigned: true, isCorrectlySigned: true, signingKeyID: sk.keyID!, myKeyID: sk.keyID!, secureAddresses: secureAddresses, encryptedForKeyIDs: keyIDs, inviteMailContent: inviteMailContent, invitationMail: inviteMail)
                    }

                    sendOperation = session.sendOperation(with: builder.openPGPEncryptedMessageData(withEncryptedData: sendData), from: userID, recipients: encPGP)

                    sendOperation.start(callback)
                    if (ordered[CryptoScheme.UNKNOWN] == nil || ordered[CryptoScheme.UNKNOWN]!.count == 0) && !loggingMail {
                        createSendCopy(sendData: builder.openPGPEncryptedMessageData(withEncryptedData: sendData))
                    }
                    if Logger.logging && loggingMail {
                        createLoggingSendCopy(sendData: builder.openPGPEncryptedMessageData(withEncryptedData: sendData))
                    }

                    if let html = htmlContent {
                        builder.htmlBody = html
                    } else {
                        builder.textBody = message
                    }
                } else {
                    callback(NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError, userInfo: nil))
                }
            }

            if let unenc = ordered[CryptoScheme.UNKNOWN], !loggingMail {
                if unenc.count > 0 {
                    if let html = htmlContent {
                        builder.htmlBody = html
                    } else {
                        builder.textBody = message
                    }

                    sendData = builder.data()
                    sendOperation = session.sendOperation(with: sendData, from: userID, recipients: unenc)
                    if unenc.count == allRec.count && !loggingMail {
                        var inviteMailContent: String? = nil
                        if inviteMail {
                            inviteMailContent = textparts.description
                        }
                        Logger.log(sent: fromLogging, to: toLogging, cc: ccLogging, bcc: bccLogging, subject: subject, bodyLength: ("\n" + message).count, isEncrypted: false, decryptedBodyLength: ("\n" + message).count, decryptedWithOldPrivateKey: false, isSigned: false, isCorrectlySigned: false, signingKeyID: "", myKeyID: "", secureAddresses: [], encryptedForKeyIDs: [], inviteMailContent: inviteMailContent, invitationMail: inviteMail)
                    }
                    sendOperation.start(callback)
                    if !loggingMail {
                        createSendCopy(sendData: sendData)
                    }
                }
            }

            if let encPGP = ordered[CryptoScheme.PGP], encPGP.count > 0 {
            } else if let unenc = ordered[CryptoScheme.UNKNOWN], unenc.count > 0, !loggingMail {
            } else {
                let error = NSError.init(domain: MCOErrorDomain, code: MCOErrorCode.sendMessage.rawValue, userInfo: nil) as Error
                callback(error)
            }
        } else {
            let error = NSError.init(domain: MCOErrorDomain, code: MCOErrorCode.sendMessage.rawValue, userInfo: nil) as Error
            callback(error)
        }
    }

    fileprivate func createSendCopy(sendData: Data) {
        let sentFolder = UserManager.backendSentFolderPath
        if !DataHandler.handler.existsFolder(with: sentFolder) {
            let op = IMAPSession.createFolderOperation(sentFolder)
            op?.start({ error in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.createSendCopy(sendData: sendData)}, completionCallback: nil)
                    return
                }
                let op = self.IMAPSession.appendMessageOperation(withFolder: sentFolder, messageData: sendData, flags: MCOMessageFlag.mdnSent)
                op?.start({ error, _ in
                    guard error == nil else {
                        self.errorhandling(error: error, originalCall: {self.createSendCopy(sendData: sendData)}, completionCallback: nil)
                        return
                    }
                })
            })
        } else {
            let op = IMAPSession.appendMessageOperation(withFolder: sentFolder, messageData: sendData, flags: MCOMessageFlag.mdnSent)
            op?.start({ error, _ in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.createSendCopy(sendData: sendData)}, completionCallback: nil)
                    return
                }
            })
        }
    }

    fileprivate func createLoggingSendCopy(sendData: Data) {
        let sentFolder = UserManager.loadUserValue(.loggingFolderPath) as! String
        if !DataHandler.handler.existsFolder(with: sentFolder) {
            let op = IMAPSession.createFolderOperation(sentFolder)
            op?.start({ error in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.createLoggingSendCopy(sendData: sendData)}, completionCallback: nil)
                    return
                }
                let op = self.IMAPSession.appendMessageOperation(withFolder: sentFolder, messageData: sendData, flags: MCOMessageFlag.mdnSent)
                op?.start({ error, _ in
                    guard error == nil else {
                        self.errorhandling(error: error, originalCall: {self.createLoggingSendCopy(sendData: sendData)}, completionCallback: nil)
                        return
                    }
                })
            })
        } else {
            let op = IMAPSession.appendMessageOperation(withFolder: sentFolder, messageData: sendData, flags: MCOMessageFlag.mdnSent)
            op?.start({ error, _ in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.createLoggingSendCopy(sendData: sendData)}, completionCallback: nil)
                    return
                }
            })
        }
    }

    func createDraft(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, callback: @escaping (Error?) -> Void) {
        let builder = MCOMessageBuilder()

        createHeader(builder, toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject)

        var allRec: [String] = []
        allRec.append(contentsOf: toEntrys)
        allRec.append(contentsOf: ccEntrys)
        // What about BCC??

        var sendData: Data

        let pgp = SwiftPGP()
        let mykey = DataHandler.handler.prefSecretKey()
        if  allRec.reduce(true, { $0 && DataHandler.handler.hasKey(adr: $1) }) {
            let receiverIds = [mykey.keyID] as! [String]
            if Logger.logging {
                var to: [Mail_Address?] = []
                for addr in toEntrys {
                    to.append(DataHandler.handler.findMailAddress(adr: addr))
                }

                var cc: [Mail_Address?] = []
                for addr in ccEntrys {
                    cc.append(DataHandler.handler.findMailAddress(adr: addr))
                }

                var bcc: [Mail_Address?] = []
                for addr in bccEntrys {
                    bcc.append(DataHandler.handler.findMailAddress(adr: addr))
                }
                Logger.log(createDraft: to, cc: cc, bcc: bcc, subject: subject, bodyLength: message.count, isEncrypted: true, isSigned: true, myKeyID: mykey.keyID ?? "")
            }
            let cryptoObject = pgp.encrypt(plaintext: "\n" + message, ids: receiverIds, myId: mykey.keyID!)
            if let encData = cryptoObject.chiphertext {
                sendData = builder.openPGPEncryptedMessageData(withEncryptedData: encData)

                let drafts = UserManager.backendDraftFolderPath

                if !DataHandler.handler.existsFolder(with: drafts) {
                    let op = IMAPSession.createFolderOperation(drafts)
                    op?.start({ error in
                        guard error == nil else {
                            self.errorhandling(error: error, originalCall: {self.createDraft(toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, message: message, callback: callback)}, completionCallback: nil)
                            return
                        }
                        self.saveDraft(data: sendData, callback: callback) })
                } else {
                    saveDraft(data: sendData, callback: callback)
                }
            } else {
                callback(NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError, userInfo: nil))
            }
        } else {
            if Logger.logging {
                var to: [Mail_Address?] = []
                for addr in toEntrys {
                    to.append(DataHandler.handler.findMailAddress(adr: addr))
                }

                var cc: [Mail_Address?] = []
                for addr in ccEntrys {
                    cc.append(DataHandler.handler.findMailAddress(adr: addr))
                }

                var bcc: [Mail_Address?] = []
                for addr in bccEntrys {
                    bcc.append(DataHandler.handler.findMailAddress(adr: addr))
                }
                Logger.log(createDraft: to, cc: cc, bcc: bcc, subject: subject, bodyLength: message.count, isEncrypted: false, isSigned: false, myKeyID: "")
            }
            builder.textBody = message
            sendData = builder.data()

            let drafts = UserManager.backendDraftFolderPath

            if !DataHandler.handler.existsFolder(with: drafts) {
                let op = IMAPSession.createFolderOperation(drafts)
                op?.start({ error in
                    guard error == nil else {
                        self.errorhandling(error: error, originalCall: {self.createDraft(toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, message: message, callback: callback)}, completionCallback: nil)
                        return
                    }
                    self.saveDraft(data: sendData, callback: callback) })
            } else {
                saveDraft(data: sendData, callback: callback)
            }
        }
    }

    fileprivate func saveDraft(data: Data, callback: @escaping (Error?) -> Void) {
        let op = IMAPSession.appendMessageOperation(withFolder: UserManager.backendDraftFolderPath, messageData: data, flags: MCOMessageFlag.draft)
        op?.start({ error, _ in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.saveDraft(data: data, callback: callback)}, completionCallback: callback)
                return
            }
            callback(nil)
            
        })
    }

    private func setupIMAPSession() -> MCOIMAPSession {
        let imapsession = MCOIMAPSession()
        if let hostname = UserManager.loadUserValue(Attribute.imapHostname) as? String {
            imapsession.hostname = hostname
        }
        if let port = UserManager.loadUserValue(Attribute.imapPort) as? UInt32 {
            imapsession.port = port
        }
        if let username = UserManager.loadUserValue(Attribute.userAddr) as? String {
            imapsession.username = username
        }
        imapsession.authType = UserManager.loadImapAuthType()

        if UserManager.loadImapAuthType() == MCOAuthType.xoAuth2 {
            imapsession.oAuth2Token = EmailHelper.singleton().authorization?.authState.lastTokenResponse?.accessToken
        } else if let pw = UserManager.loadUserValue(Attribute.userPW) as? String {
            imapsession.password = pw
        }

        if let connType = UserManager.loadUserValue(Attribute.imapConnectionType) as? Int {
            imapsession.connectionType = MCOConnectionType(rawValue: connType)
        }
        return imapsession
    }

    func startIMAPIdleIfSupported() {
        if let supported = IMAPIdleSupported {
            if supported && IMAPIdleSession == nil {
                IMAPIdleSession = setupIMAPSession()
                let op = IMAPIdleSession!.idleOperation(withFolder: INBOX, lastKnownUID: UInt32(DataHandler.handler.findFolder(with: INBOX).maxID))
                op?.start({ error in
                    guard error == nil else {
                        self.errorhandling(error: error, originalCall: {self.startIMAPIdleIfSupported()}, completionCallback: nil)
                        return
                    }
                    self.IMAPIdleSession = nil
                    let folder = DataHandler.handler.findFolder(with: self.INBOX)
                    self.updateFolder(folder: folder, completionCallback: { error in
                        guard error == nil else {
                            self.errorhandling(error: error, originalCall: {self.startIMAPIdleIfSupported()}, completionCallback: nil)
                            return
                        }
                        self.startIMAPIdleIfSupported() })
                })
            }
        } else {
            checkIdleSupport()
        }
    }

    private func checkIdleSupport() {
        let op = setupIMAPSession().capabilityOperation()
        op?.start({ (error, capabilities) in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.checkIdleSupport()}, completionCallback: nil)
                return
            }

            if let c = capabilities {
                self.IMAPIdleSupported = c.contains(UInt64(MCOIMAPCapability.idle.rawValue))
                self.startIMAPIdleIfSupported()
            }
        })
    }

    fileprivate func createSMTPSession() -> MCOSMTPSession {
        let session = MCOSMTPSession()
        session.authType = UserManager.loadSmtpAuthType()
        if UserManager.loadSmtpAuthType() == MCOAuthType.xoAuth2 {
            if let lastToken = EmailHelper.singleton().authorization?.authState.lastTokenResponse {
                session.oAuth2Token = lastToken.accessToken
            }
        } else {
            session.password = UserManager.loadUserValue(Attribute.userPW) as! String
        }
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = UserManager.loadUserValue(Attribute.userAddr) as! String
        session.authType = UserManager.loadSmtpAuthType()
        session.connectionType = MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int)
        return session
    }

    func addFlag(_ uid: UInt64, flags: MCOMessageFlag, folder: String?) {
        var folderName = INBOX
        if let folder = folder {
            folderName = folder
        }

        let f = DataHandler.handler.findFolder(with: folderName)
        let folderstatus = IMAPSession.folderStatusOperation(folderName)
        folderstatus?.start { (error, status) -> Void in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.addFlag(uid, flags: flags, folder: folderName)}, completionCallback: nil)
                return
            }
            if let status = status {
                let uidValidity = status.uidValidity
                if uidValidity == f.uidvalidity {
                    let op = self.IMAPSession.storeFlagsOperation(withFolder: folderName, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.set, flags: flags)
                    op?.start { error -> Void in
                        guard error == nil else {
                            self.errorhandling(error: error, originalCall: {self.addFlag(uid, flags: flags, folder: folderName)}, completionCallback: nil)
                            return
                        }
                        if flags.contains(MCOMessageFlag.deleted) {
                            let operation = self.IMAPSession.expungeOperation(folderName)
                            operation?.start({ err in
                                guard err == nil else {
                                     self.errorhandling(error: error, originalCall: {self.addFlag(uid, flags: flags, folder: folderName)}, completionCallback: nil)
                                    return
                                }
                                DataHandler.handler.deleteMail(with: uid)
                            })
                        }
                    }
                }
            }
        }
    }

    func removeFlag(_ uid: UInt64, flags: MCOMessageFlag, folder: String?) {
        var folderName = INBOX
        if let folder = folder {
            folderName = folder
        }
        let f = DataHandler.handler.findFolder(with: folderName)
        let folderstatus = IMAPSession.folderStatusOperation(folderName)
        folderstatus?.start { (error, status) -> Void in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.removeFlag(uid, flags: flags, folder: folderName)}, completionCallback: nil)
                return
            }
            if let status = status {
                let uidValidity = status.uidValidity
                if uidValidity == f.uidvalidity {
                    let op = self.IMAPSession.storeFlagsOperation(withFolder: folderName, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.remove, flags: flags)

                    op?.start { error -> Void in
                        guard error == nil else {
                            self.errorhandling(error: error, originalCall: {self.removeFlag(uid, flags: flags, folder: folderName)}, completionCallback: nil)
                            return
                        }
                    }
                }
            }
        }
    }



    func loadMailsForRecord(_ record: KeyRecord, folderPath: String, completionCallback: @escaping ((_ error: Error?) -> ())) {
        let folder = DataHandler.handler.findFolder(with: folderPath)
        let folderstatus = IMAPSession.folderStatusOperation(folderPath)
        folderstatus?.start { (error, status) -> Void in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.loadMailsForRecord(record, folderPath: folderPath,  completionCallback: completionCallback)}, completionCallback: completionCallback)
                return
            }
            if let status = status {
                let uidValidity = status.uidValidity

                folder.uidvalidity = uidValidity
                let addresses: [MailAddress]
                addresses = record.addresses

                for adr in addresses {
                    let searchExpr: MCOIMAPSearchExpression = MCOIMAPSearchExpression.search(from: adr.mailAddress)
                    let searchOperation: MCOIMAPSearchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folderPath, expression: searchExpr)

                    searchOperation.start { (err, indices) -> Void in
                        guard err == nil else {
                            self.errorhandling(error: err, originalCall: {self.loadMailsForRecord(record, folderPath: folderPath, completionCallback: completionCallback)}, completionCallback: completionCallback)
                            return
                        }

                        let ids = indices as MCOIndexSet?
                        if let setOfIndices = ids {
                            for mail in record.mails {
                                setOfIndices.remove(mail.uid)
                            }
                            if setOfIndices.count() == 0 {
                                completionCallback(nil)
                                return
                            }
                            self.loadMessagesFromServer(setOfIndices, folderPath: folderPath, record: record, completionCallback: completionCallback)
                        }
                    }
                }
            }
        }
    }

    func loadMailsForInbox(completionCallback: @escaping ((_ error: Error?) -> ())) {
        let folder = DataHandler.handler.findFolder(with: INBOX)
        let folderstatus = IMAPSession.folderStatusOperation(folder.path)
        folderstatus?.start { (error, status) -> Void in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.loadMailsForInbox(completionCallback: completionCallback)}, completionCallback: completionCallback)
                return
            }
            if let status = status {
                let uidValidity = status.uidValidity
                folder.uidvalidity = uidValidity
                self.olderMails(folder: folder, completionCallback: completionCallback)
            }
        }
    }

    private func loadMessagesFromServer(_ uids: MCOIndexSet, folderPath: String, maxLoad: Int = MailHandler.MAXMAILS, record: KeyRecord?, completionCallback: @escaping ((_ error: Error?) -> ())) {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue)
        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = [AUTOCRYPTHEADER, SETUPMESSAGE]
        if uids.count() == 0 {
            completionCallback(nil)
            return
        }
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                self.errorhandling(error: err, originalCall: {self.loadMessagesFromServer(uids, folderPath: folderPath, maxLoad: maxLoad, record: record, completionCallback: completionCallback)}, completionCallback: completionCallback)
                return
            }

            var calledMails = 0
            if let msgs = msg {
                let dispatchGroup = DispatchGroup()
                for m in msgs.reversed() {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    dispatchGroup.enter()

                    let op = self.IMAPSession.fetchParsedMessageOperation(withFolder: folderPath, uid: message.uid)
                    op?.start { err, data in
                        guard err == nil else {
                            self.errorhandling(error: err, originalCall: {self.loadMessagesFromServer(uids, folderPath: folderPath, maxLoad: maxLoad, record: record, completionCallback: completionCallback)}, completionCallback: completionCallback)
                            return
                        }
                        self.parseMail(parser: data, message: message, record: record, folderPath: folderPath)
                        dispatchGroup.leave()
                    }
                    calledMails += 1
                    if calledMails > maxLoad {
                        break
                    }
                }
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    self.IMAPSession.disconnectOperation().start({ err2 in
                        guard err2 == nil else {
                            self.errorhandling(error: err2, originalCall: {self.loadMessagesFromServer(uids, folderPath: folderPath, maxLoad: maxLoad, record: record, completionCallback: completionCallback)}, completionCallback: completionCallback)
                            return
                        }
                    })
                    completionCallback(nil)
                }
            }
        }
    }

    private func parseMail(parser: MCOMessageParser?, message: MCOIMAPMessage, record: KeyRecord?, folderPath: String) {
        var rec: [MCOAddress] = []
        var cc: [MCOAddress] = []
        var autocrypt: AutocryptContact? = nil
        var newKeyIds = [String]()

        var secretKey: String? = nil
        let header = message.header

        let msgID = header?.messageID
        let userAgent = header?.userAgent
        var references = [String]()
        if let refs = header?.references {
            for ref in refs {
                if let string = ref as? String {
                    references.append(string)
                }
            }
        }

        if header?.from == nil {
            // Drops mails with no from field. Otherwise it becomes ugly with no ezcontact,fromadress etc.
            return
        }


        if let _ = header?.extraHeaderValue(forName: AUTOCRYPTHEADER) {
            autocrypt = AutocryptContact(header: header!)
        }

        if let _ = header?.extraHeaderValue(forName: SETUPMESSAGE) {
            // TODO: Distinguish between other keys (future work)
            return
        }


        if let to = header?.to {
            for r in to {
                rec.append(r as! MCOAddress)
            }
        }
        if let c = header?.cc {
            for r in c {
                cc.append(r as! MCOAddress)
            }
        }

        if let data = parser?.data() {
            var msgParser = MCOMessageParser(data: data)
            var isEnc = false
            var html: String
            var body: String
            var lineArray: [String]
            var dec: CryptoObject? = nil

            for a in (msgParser?.attachments())! {
                let at = a as! MCOAttachment
                if at.mimeType == "application/pgp-encrypted" {
                    isEnc = true
                }
                if isEnc && at.mimeType == "application/octet-stream" {
                    msgParser = MCOMessageParser(data: at.data)
                }
                newKeyIds.append(contentsOf: parsePublicKeys(attachment: at))
                if let sk = parseSecretKey(attachment: at) {
                    secretKey = sk
                }

            }
            if isEnc {
                html = msgParser!.plainTextRendering()
                lineArray = html.components(separatedBy: "\n")
                lineArray.removeFirst(4)
                body = lineArray.joined(separator: "\n")
                body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                body.append("\n")
                dec = decryptText(body: body, from: message.header.from, autocrypt: autocrypt)
                if (dec?.plaintext != nil) {
                    msgParser = MCOMessageParser(data: dec?.decryptedData)
                    html = msgParser!.plainTextBodyRenderingAndStripWhitespace(false)
                    lineArray = html.components(separatedBy: "\n")
                    body = lineArray.joined(separator: "\n")
                    body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    body.append("\n")
                    for a in (msgParser?.attachments())! {
                        let at = a as! MCOAttachment
                        newKeyIds.append(contentsOf: parsePublicKeys(attachment: at))
                        if let sk = parseSecretKey(attachment: at) {
                            secretKey = sk
                        }

                    }
                }
            } else {
                html = msgParser!.plainTextRendering()

                lineArray = html.components(separatedBy: "\n")
                lineArray.removeFirst(4)
                body = lineArray.joined(separator: "\n")
                body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                body.append("\n")

                if let chipher = findInlinePGP(text: body) {
                    dec = decryptText(body: chipher, from: message.header.from, autocrypt: autocrypt)
                    if dec != nil {
                        if let text = dec?.decryptedText {
                            body = text
                        }
                    }
                }
            }

            if let header = header, let from = header.from, let date = header.date {
                if StudySettings.studyMode && from.mailbox.lowercased().contains("bitcoin.de") {
                    StudySettings.bitcoinMails = true
                }
                let mail = DataHandler.handler.createMail(UInt64(message.uid), sender: from, receivers: rec, cc: cc, time: date, received: true, subject: header.subject ?? "", body: body, flags: message.flags, record: record, autocrypt: autocrypt, decryptedData: dec, folderPath: folderPath, secretKey: secretKey, references: references, mailagent: userAgent, messageID: msgID)
                if let m = mail {
                    let pgp = SwiftPGP()
                    if let autoc = autocrypt {
                        if let publickeys = try? pgp.importKeys(key: autoc.key, pw: nil, isSecretKey: false, autocrypt: true) {
                            for pk in publickeys {
                                _ = DataHandler.handler.newPublicKey(keyID: pk, cryptoType: CryptoScheme.PGP, adr: from.mailbox, autocrypt: true, firstMail: mail)
                            }
                        }
                    }
                    for keyId in newKeyIds {
                        _ = DataHandler.handler.newPublicKey(keyID: keyId, cryptoType: CryptoScheme.PGP, adr: from.mailbox, autocrypt: false, firstMail: mail)
                    }
                    //                Logger.queue.async(flags: .barrier) {
                    Logger.log(received: m)
                }
            }
        }
    }

    private func findInlinePGP(text: String) -> String? {
        var range = text.range(of: "-----BEGIN PGP MESSAGE-----")
        if let lower = range?.lowerBound {
            range = text.range(of: "-----END PGP MESSAGE-----")
            if let upper = range?.upperBound {
                let retValue = text.substring(to: upper).substring(from: lower)
                // We do not try to decrypt a previous mails.
                if retValue.contains(">"){
                    return nil
                }
                return retValue
            }
        }
        return nil
    }

    private func parsePublicKeys(attachment: MCOAttachment) -> [String] {
        var newKey = [String]()
        if let content = attachment.decodedString() {
            if content.contains("-----BEGIN PGP PUBLIC KEY BLOCK-----") {
                if let start = content.range(of: "-----BEGIN PGP PUBLIC KEY BLOCK-----") {
                    if let end = content.range(of: "-----END PGP PUBLIC KEY BLOCK-----\n") {
                        let s = start.lowerBound
                        let e = end.upperBound
                        let pk = content[s..<e]
                        let pgp = SwiftPGP()
                        if let keyId = try? pgp.importKeys(key: pk, pw: nil, isSecretKey: false, autocrypt: false) {
                            newKey.append(contentsOf: keyId)
                        }
                    }
                }
            }
        } else if attachment.mimeType == "application/octet-stream", let content = String(data: attachment.data, encoding: String.Encoding.utf8), content.hasPrefix("-----BEGIN PGP PUBLIC KEY BLOCK-----") && (content.hasSuffix("-----END PGP PUBLIC KEY BLOCK-----") || content.hasSuffix("-----END PGP PUBLIC KEY BLOCK-----\n")) {
            let pgp = SwiftPGP()
            if let keyId = try? pgp.importKeys(key: content, pw: nil, isSecretKey: false, autocrypt: false) {
                newKey.append(contentsOf: keyId)
            }
        } else if attachment.mimeType == "application/pgp-keys" {
            let pgp = SwiftPGP()
            if let keyIds = try? pgp.importKeys(data: attachment.data, pw: nil, secret: false) {
                newKey.append(contentsOf: keyIds)
            }
        }
        return newKey
    }



    private func parseSecretKey(attachment: MCOAttachment) -> String? {
        if let content = attachment.decodedString() {
            if content.contains("-----BEGIN PGP PRIVATE KEY BLOCK-----") {
                if let start = content.range(of: "-----BEGIN PGP PRIVATE KEY BLOCK-----"),
                    let end = content.range(of: "-----END PGP PRIVATE KEY BLOCK-----") {
                    let s = start.lowerBound
                    let e = end.upperBound
                    let sk = content[s..<e]
                    return sk
                }
            }
        }
        return nil
    }

    private func decryptText(body: String, from: MCOAddress?, autocrypt: AutocryptContact?) -> CryptoObject? {
        var sender: String? = nil
        if let fromMCO = from {
            sender = fromMCO.mailbox
        }
        if let data = body.data(using: String.Encoding.utf8, allowLossyConversion: true) as Data? {
            let pgp = SwiftPGP()
            var keyIds = [String]()
            if sender != nil, let adr = DataHandler.handler.findMailAddress(adr: sender!) {
                for k in adr.publicKeys {
                    keyIds.append(k.keyID)
                }
            }
            if let a = autocrypt {
                if let key = try? pgp.importKeys(key: a.key, pw: nil, isSecretKey: false, autocrypt: true) {
                    keyIds.append(contentsOf: key)
                }
            }
            let secretkeys = DataHandler.handler.findSecretKeys()
            var decIds = [String]()
            for sk in secretkeys {
                if let id = sk.keyID {
                    decIds.append(id)
                }
            }

            return pgp.decrypt(data: data, decryptionIDs: decIds, verifyIds: keyIds, fromAdr: sender)
        }

        return nil
    }


    func checkSMTP(_ completion: @escaping (Error?) -> Void) {
        let useraddr = UserManager.loadUserValue(Attribute.userAddr) as! String

        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = useraddr
        if UserManager.loadSmtpAuthType() == MCOAuthType.xoAuth2 {
            session.oAuth2Token = EmailHelper.singleton().authorization?.authState.lastTokenResponse?.accessToken
        } else if let pw = UserManager.loadUserValue(Attribute.userPW) as? String {
            session.password = pw
        }
        session.authType = UserManager.loadSmtpAuthType()
        session.connectionType = MCOConnectionType.init(rawValue: UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int)

        session.checkAccountOperationWith(from: MCOAddress.init(mailbox: useraddr)).start(completion)

    }

    func checkIMAP(_ completion: @escaping (Error?) -> Void) {
        self.setupIMAPSession().checkAccountOperation().start(completion)
    }

    func move(mails: [PersistentMail], from: String, to: String, folderCreated: Bool = false) {
        let uids = MCOIndexSet()

        if !DataHandler.handler.existsFolder(with: to) && !folderCreated {
            let op = IMAPSession.createFolderOperation(to)
            op?.start({ error in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.move(mails: mails, from: from, to: to)}, completionCallback: nil)
                    return
                }
                self.move(mails: mails, from: from, to: to, folderCreated: true)
            })
        } else {
            let folderstatusFrom = IMAPSession.folderStatusOperation(from)
            folderstatusFrom?.start { (error, status) -> Void in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.move(mails: mails, from: from, to: to)}, completionCallback: nil)
                    return
                }
                if let statusFrom = status {
                    let uidValidity = statusFrom.uidValidity
                    let f = DataHandler.handler.findFolder(with: from)
                    if uidValidity == f.uidvalidity {
                        for mail in mails {
                            if mail.uidvalidity == uidValidity {
                                uids.add(mail.uid)
                                mail.folder.removeFromMails(mail)
                                if let record = mail.record {
                                    record.removeFromPersistentMails(mail)
                                    if record.mailsInFolder(folder: f).count == 0 {
                                        f.removeFromKeyRecords(record)
                                    }
                                }
                                DataHandler.handler.delete(mail: mail)
                            }
                        }
                        let op = self.IMAPSession.moveMessagesOperation(withFolder: from, uids: uids, destFolder: to)
                        op?.start {
                            (err, vanished) -> Void in
                            guard err == nil else {
                                self.errorhandling(error: err, originalCall: {self.move(mails: mails, from: from, to: to)}, completionCallback: nil)
                                return
                            }
                        }
                    } else {
                        f.uidvalidity = uidValidity
                    }
                }
            }
        }
    }


    func allFolders(_ completion: @escaping (Error?, [Any]?) -> Void) {
        let op = IMAPSession.fetchAllFoldersOperation()
        op?.start(completion)
    }


    private func initFolder(folder: Folder, completionCallback: @escaping ((Error?) -> ())) {
        let folderPath = folder.path
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        let toFetchIDs = MCOIndexSet()


        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                self.errorhandling(error: err, originalCall: {self.initFolder(folder: folder, completionCallback: completionCallback)}, completionCallback: completionCallback)
                return
            }
            if let msgs = msg {
                folder.lastUpdate = Date()
                for m in msgs {
                    if let message = m as? MCOIMAPMessage {
                        toFetchIDs.add(UInt64(message.uid))
                    }
                }
                self.loadMessagesFromServer(toFetchIDs, folderPath: folderPath, maxLoad: 50, record: nil, completionCallback: completionCallback)
            } else {
                completionCallback(nil)
            }
        }
    }

    private func initInbox(inbox: Folder, completionCallback: @escaping ((Error?) -> ())) {
        if let date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) {
            loadMailsSinceDate(folder: inbox, since: date, maxLoad: 100, completionCallback: completionCallback)
        } else {
            initFolder(folder: inbox, completionCallback: completionCallback)
        }

    }

    func updateFolder(folder: Folder, completionCallback: @escaping ((Error?) -> ())) {
        let folderstatus = IMAPSession.folderStatusOperation(folder.path)
        folderstatus?.start { (error, status) -> Void in
            guard error == nil else {
                self.errorhandling(error: error, originalCall: {self.updateFolder(folder: folder, completionCallback: completionCallback)}, completionCallback: completionCallback)
                return
            }
            if let status = status {
                let uidValidity = status.uidValidity
                folder.uidvalidity = uidValidity


                if let date = folder.lastUpdate {
                    self.loadMailsSinceDate(folder: folder, since: date, completionCallback: completionCallback)
                } else {
                    if folder.path == UserManager.backendInboxFolderPath || folder.path.lowercased() == "INBOX".lowercased() {
                        self.initInbox(inbox: folder, completionCallback: completionCallback)
                    } else {
                        self.initFolder(folder: folder, completionCallback: completionCallback)
                    }
                }
            }
        }
    }

    private func olderMails(folder: Folder, completionCallback: @escaping ((Error?) -> ())) {
        let folderPath = folder.path
        if let mails = folder.mails {
            var oldestDate: Date?
            for m in mails {
                if let mail = m as? PersistentMail {
                    if oldestDate == nil || mail.date < oldestDate {
                        oldestDate = mail.date
                    }
                }
            }
            if let date = oldestDate {
                let searchExp = MCOIMAPSearchExpression.search(before: date)
                let searchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folderPath, expression: searchExp)

                searchOperation?.start { (err, uids) -> Void in
                    guard err == nil else {
                         self.errorhandling(error: err, originalCall: {self.olderMails(folder: folder, completionCallback: completionCallback)}, completionCallback: completionCallback)
                        return
                    }
                    if let ids = uids {
                        folder.lastUpdate = Date()
                        self.loadMessagesFromServer(ids, folderPath: folderPath, record: nil, completionCallback: completionCallback)
                    } else {
                        completionCallback(nil)
                    }
                }
            } else {
                initFolder(folder: folder, completionCallback: completionCallback)
            }
        } else {
            initFolder(folder: folder, completionCallback: completionCallback)
        }

    }


    private func loadMailsSinceDate(folder: Folder, since: Date, maxLoad: Int = MailHandler.MAXMAILS, completionCallback: @escaping ((Error?) -> ())) {
        let folderPath = folder.path
        let searchExp = MCOIMAPSearchExpression.search(since: since)
        let searchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folderPath, expression: searchExp)

        searchOperation?.start { (err, uids) -> Void in
            guard err == nil else {
                self.errorhandling(error: err, originalCall: {self.loadMailsSinceDate(folder: folder, since: since, completionCallback: completionCallback)}, completionCallback: completionCallback)
                return
            }
            if let ids = uids {
                folder.lastUpdate = Date()
                self.loadMessagesFromServer(ids, folderPath: folderPath, maxLoad: maxLoad, record: nil, completionCallback: completionCallback)
            } else {
                completionCallback(nil)
            }
        }

    }

    func retryWithRefreshedOAuth(completion: @escaping () -> ()) {
        guard shouldTryRefreshOAUTH else {
            return
        }
        EmailHelper.singleton().checkIfAuthorizationIsValid({ authorized in
            if authorized {
                self.IMAPSes = nil
            }
            completion()
        })
    }
    
    private func errorhandling(error: Error?, originalCall: @escaping () -> (), completionCallback: (((Error?) -> ()))?){
        // maybe refreshing oauth?
        if self.shouldTryRefreshOAUTH {
            self.retryWithRefreshedOAuth {
                originalCall()
            }
            return
        }
        if completionCallback != nil {
            completionCallback!(error)
        }
    }
}
