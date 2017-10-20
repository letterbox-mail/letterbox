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
let ADDR = "adr"
let TYPE = "type"
let ENCRYPTION = "prefer-encrypted"
let KEY = "key"


class AutocryptContact {
    var addr: String = ""
    var type: CryptoScheme = .PGP
    var prefer_encryption: EncState = EncState.NOAUTOCRYPT
    var key: String = ""

    init(addr: String, type: String, prefer_encryption: String, key: String) {
        self.addr = addr
        // TODO: Other crypto schemes?
        _ = setPrefer_encryption(prefer_encryption)
        self.key = key
    }


    convenience init(header: MCOMessageHeader) {
        var autocrypt = header.extraHeaderValue(forName: AUTOCRYPTHEADER)
        var field: [String]
        var addr = ""
        var type = "1" // Default value since no one else uses autocrypt...
        var pref = ""
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
                        break
                    case TYPE:
                        type = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    case ENCRYPTION:
                        pref = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    case KEY:
                        if value.characters.count > 0 {
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

    func validateContact() -> Bool {
        if addr != "" && type != .UNKNOWN && key != "" {
            return true
        }
        return false
    }

    func setPrefer_encryption(_ input: String) -> Bool {
        let pref = input.lowercased()
        if pref == "yes" || pref == "mutal" {
            self.prefer_encryption = EncState.MUTAL
            return true
        } else if pref == "no" {
            self.prefer_encryption = EncState.NOPREFERENCE
            return true
        }
        prefer_encryption = EncState.NOPREFERENCE
        return false
    }

    func toString() -> String {
        return "Addr: \(addr) | type: \(type) | encryption? \(prefer_encryption) key size: \(key.characters.count)"
    }
}

class MailHandler {

    var delegate: MailHandlerDelegator?

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

    func addAutocryptHeader(_ builder: MCOMessageBuilder) {
        let adr = (UserManager.loadUserValue(Attribute.userAddr) as! String).lowercased()
        let keyIDs = DataHandler.handler.findSecretKeys()
        if keyIDs.count > 0{
            let pgp = SwiftPGP()
            if let id = keyIDs[0].keyID{
                let enc = "yes"
                if let key = pgp.exportKey(id: id, isSecretkey: false, autocrypt: true){
                    var string = "adr = " + adr + "; type = 1;"
                    if enc == "yes"{
                        string = string + "prefer-encrypted = mutal"
                    }
                    string = string + ";key = "+key
                    builder.header.setExtraHeaderValue(string, forName: AUTOCRYPTHEADER)
                }
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

        addAutocryptHeader(builder)

    }
    
    private func orderReceiver(receiver: [String]) -> [CryptoScheme: [MCOAddress]]{
        var orderedReceiver = [CryptoScheme: [MCOAddress]]()
        orderedReceiver[CryptoScheme.PGP] = [MCOAddress]()
        orderedReceiver[CryptoScheme.UNKNOWN] = [MCOAddress]()

        for r in receiver{
            let mco = MCOAddress(displayName: r, mailbox: r)
            if let adr = DataHandler.handler.findMailAddress(adr: r){
                if adr.hasKey{ //TODO: CONSIDER AUTOCRYPT!
                    orderedReceiver[CryptoScheme.PGP]?.append(mco!)
                }
                else{
                    orderedReceiver[CryptoScheme.UNKNOWN]?.append(mco!)
                }
            }
        }
        return orderedReceiver
    }
    
    private func addKeys(adrs: [MCOAddress]) -> [String]{
        var ids = [String]()
        for a in adrs{
            if let adr = DataHandler.handler.findMailAddress(adr: a.mailbox), let key = adr.Key?.keyID {
                ids.append(key)
            }
        }
       
        return ids
    }
    
    func sendSecretKey(keyData: Data, passcode: String, callback: @escaping (Error?) -> Void){
        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        let session = createSMTPSession()
        let builder = MCOMessageBuilder()
        let userID :MCOAddress = MCOAddress(displayName: useraddr, mailbox: useraddr)
      
        createHeader(builder, toEntrys: [useraddr], ccEntrys: [], bccEntrys: [], subject: "Autocrypt Setup Message 2")
        builder.header.setExtraHeaderValue("v1", forName: "Autocrypt-Setup-Message")
        
        
        /*
        if let key = MCOAttachment.init(rfc822Message: keyData){
            print("ID: \(key.contentID)")
            print("Type: \(key.mimeType)")
            // Use and test later:
            // see https://autocrypt.readthedocs.io/en/latest/level1.html#autocrypt-setup-message
            // key.mimeType = "application/autocrypt-key-backup"
            key.mimeType = "application/pgp-encrypted"
            builder.addAttachment(key)
        }
        let plain = MCOAttachment.init(text: "Klartext!")
        builder.addAttachment(plain)
        
 */
        builder.addAttachment(MCOAttachment.init(text: NSLocalizedString("This message contains a secret for reading secure mails on other devices. \n 1) Input the passcode from your smartphone to unlock the message on your other device. \n 2) Import the secret into your pgp program on the device.  \n\n For more information visit: www.enzevalos.de/other", comment: "Message when sending the secret key")))

        let key = MCOAttachment.init(rfc822Message: keyData)
        builder.addAttachment(key)
        
     
        let sendOperation = session.sendOperation(with: builder.data() , from: userID, recipients: [userID])
        sendOperation?.start(callback)
        createSendCopy(sendData: builder.openPGPEncryptedMessageData(withEncryptedData: keyData))
    }
    

    func send(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, sendEncryptedIfPossible: Bool = true, callback: @escaping (Error?) -> Void) {

        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        let session = createSMTPSession()
        let builder = MCOMessageBuilder()

        createHeader(builder, toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject)


        var allRec: [String] = []
        allRec.append(contentsOf: toEntrys)
        allRec.append(contentsOf: ccEntrys)
        // What about BCC??
        
        let ordered = orderReceiver(receiver: allRec)

        let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)
        let secretkeys = DataHandler.handler.findSecretKeys()

        var sendData: Data
        var sendOperation: MCOSMTPSendOperation

        if let encPGP = ordered[CryptoScheme.PGP], ordered[CryptoScheme.PGP]?.count > 0, secretkeys.count > 0 {
            var keyIDs = addKeys(adrs: encPGP)
            let sk = secretkeys[0]
            //added own public key here, so we can decrypt our own message to read it in sent-folder
            keyIDs.append(sk.keyID!)
            
            let pgp = SwiftPGP()
            let cryptoObject = pgp.encrypt(plaintext: "\n" + message, ids: keyIDs, myId:sk.keyID!)
            if let encData = cryptoObject.chiphertext{
                sendData = encData
                 sendOperation = session.sendOperation(with: builder.openPGPEncryptedMessageData(withEncryptedData: sendData), from: userID, recipients: encPGP)
                //TODO handle different callbacks

                sendOperation.start(callback)
                createSendCopy(sendData: builder.openPGPEncryptedMessageData(withEncryptedData: sendData))
                
                builder.textBody = message
            } else {
                //TODO do it better
                callback(NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError, userInfo: nil))
            }
        }

        if let unenc = ordered[CryptoScheme.UNKNOWN]{
            if unenc.count > 0 {
                builder.textBody = message
                sendData = builder.data()
                sendOperation = session.sendOperation(with: sendData, from: userID, recipients: unenc)
                //TODO handle different callbacks
                sendOperation.start(callback)
                if secretkeys.count == 0{
                    createSendCopy(sendData: sendData)
                }
            }
        }
    }

    fileprivate func createSendCopy(sendData: Data) {
        let sentFolder = UserManager.backendSentFolderPath
        if !DataHandler.handler.existsFolder(with: sentFolder) {
            let op = IMAPSession.createFolderOperation(sentFolder)
            op?.start({ error in
                let op = self.IMAPSession.appendMessageOperation(withFolder: sentFolder, messageData: sendData, flags: MCOMessageFlag.mdnSent)
                op?.start({_,_ in print("done")})
            })
        }
        else {
            let op = IMAPSession.appendMessageOperation(withFolder: sentFolder, messageData: sendData, flags: MCOMessageFlag.mdnSent)
            op?.start({_,_ in print("done")})
        }
    }

    func createDraft(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, callback: @escaping (Error?) -> Void) {
        let builder = MCOMessageBuilder()
        
        createHeader(builder, toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject)
        
        var allRec: [String] = []
        allRec.append(contentsOf: toEntrys)
        allRec.append(contentsOf: ccEntrys)
        // What about BCC??
        
        //TODO add support for different Encryptions here
        var sendData: Data
        
        //TODO: Consider pref enc = false
        let pgp = SwiftPGP()
        let keys = DataHandler.handler.findSecretKeys()
        if keys.count > 0{
            let mykey = keys[0] //TODO: multiple privatekeys
            let receiverIds = [mykey.keyID] as! [String]
            let cryptoObject = pgp.encrypt(plaintext: "\n" + message, ids: receiverIds, myId: mykey.keyID!)
            if let encData = cryptoObject.chiphertext {
                sendData = builder.openPGPEncryptedMessageData(withEncryptedData: encData)
                
                let drafts = UserManager.backendDraftFolderPath
                
                if !DataHandler.handler.existsFolder(with: drafts) {
                    let op = IMAPSession.createFolderOperation(drafts)
                    op?.start({ _ in self.saveDraft(data: sendData, callback: callback)})
                }
                else {
                    saveDraft(data: sendData, callback: callback)
                }
            } else {
                //TODO do it better
                callback(NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError, userInfo: nil))
            }
        }
    }
    
    fileprivate func saveDraft(data: Data, callback: @escaping (Error?) -> Void) {
        let op = IMAPSession.appendMessageOperation(withFolder: UserManager.backendDraftFolderPath, messageData: data, flags: MCOMessageFlag.draft)
        op?.start({_,_ in callback(nil)})
    }
    
    func setupIMAPSession() -> MCOIMAPSession {
        let imapsession = MCOIMAPSession()
        imapsession.hostname = UserManager.loadUserValue(Attribute.imapHostname) as! String
        imapsession.port = UInt32(UserManager.loadUserValue(Attribute.imapPort) as! Int)
        imapsession.username = UserManager.loadUserValue(Attribute.userAddr) as! String
        imapsession.password = UserManager.loadUserValue(Attribute.userPW) as! String
        imapsession.authType = UserManager.loadImapAuthType()
        imapsession.connectionType = MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.imapConnectionType) as! Int)
        
        let y = imapsession.folderStatusOperation("INBOX")
        y?.start{(error, status) -> Void in
            print("Folder status: \(status.debugDescription)")
        }
        let x = imapsession.folderStatusOperation("INBOX")
        x?.start{(e,info) -> Void in
            print("Folder infos: \(info.debugDescription)")
        }
        
        return imapsession
    }

    func startIMAPIdleIfSupported(addNewMail: @escaping (() -> ())) {
        if let supported = IMAPIdleSupported {
            if supported && IMAPIdleSession == nil {
                IMAPIdleSession = setupIMAPSession()
                let op = IMAPIdleSession!.idleOperation(withFolder: UserManager.backendInboxFolderPath, lastKnownUID: UInt32(DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath).maxID))
                op?.start({ error in
                    guard error == nil else {
                        print("An error occured with the idle operation: \(String(describing: error))")
                        return
                    }
                    print("Something happened while idleing!")
                    self.IMAPIdleSession = nil
                    let folder = DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath)
                    self.updateFolder(folder: folder, newMailCallback: addNewMail, completionCallback: { _ in self.startIMAPIdleIfSupported(addNewMail: addNewMail) })
                })
            }
        } else {
            checkIdleSupport(addNewMail: addNewMail)
        }
    }

    func checkIdleSupport(addNewMail: @escaping (() -> ())) {
        let op = setupIMAPSession().capabilityOperation()
        op?.start({ (error, capabilities) in
            guard error == nil else {
                print("Error checking IMAP Idle capabilities: \(String(describing: error))")
                return
            }

            if let c = capabilities {
                self.IMAPIdleSupported = c.contains(UInt64(MCOIMAPCapability.idle.rawValue))
                print("IMAP Idle is \(self.IMAPIdleSupported! ? "" : "not ")supported!")
                self.startIMAPIdleIfSupported(addNewMail: addNewMail)
            }
        })
    }

    fileprivate func createSMTPSession() -> MCOSMTPSession {
        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = UserManager.loadUserValue(Attribute.userAddr) as! String
        session.password = UserManager.loadUserValue(Attribute.userPW) as! String
        session.authType = UserManager.loadSmtpAuthType()
        session.connectionType = MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int)
        return session
    }

    func addFlag(_ uid: UInt64, flags: MCOMessageFlag, folder: String = "INBOX") {
        let op = self.IMAPSession.storeFlagsOperation(withFolder: folder, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.set, flags: flags)
        op?.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            } else {
                if flags.contains(MCOMessageFlag.deleted) {
                    let operation = self.IMAPSession.expungeOperation(folder)
                    operation?.start({err in
                        if err == nil {
                            DataHandler.handler.deleteMail(with: uid)
                        }})
                }
            }
        }
    }

    func removeFlag(_ uid: UInt64, flags: MCOMessageFlag, folder: String = "INBOX") {
        let op = self.IMAPSession.storeFlagsOperation(withFolder: folder, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.remove, flags: flags)

        op?.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            }
        }
    }

    

    func loadMailsForRecord(_ record: KeyRecord, folderPath: String, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        //TODO: Init update/old
        let addresses: [MailAddress]
        addresses = record.addresses

        for adr in addresses {
            let searchExpr: MCOIMAPSearchExpression = MCOIMAPSearchExpression.search(from: adr.mailAddress)
            let searchOperation: MCOIMAPSearchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folderPath, expression: searchExpr)

            searchOperation.start { (err, indices) -> Void in
                guard err == nil else {
                    completionCallback(true)
                    return
                }

                let ids = indices as MCOIndexSet?
                if let setOfIndices = ids {
                    for mail in record.mails {
                        setOfIndices.remove(mail.uid)
                    }
                    if setOfIndices.count() == 0 {
                        completionCallback(false)
                        return
                    }
                    self.loadMessagesFromServer(setOfIndices, folderPath: folderPath, record: record, newMailCallback: newMailCallback, completionCallback: completionCallback)
                }
            }
        }
    }

    private func loadMessagesFromServer(_ uids: MCOIndexSet, folderPath: String, maxLoad: Int = MailHandler.MAXMAILS,record: KeyRecord?, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue)

        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = [AUTOCRYPTHEADER]
        
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(String(describing: err))")
                completionCallback(true)
                return
            }
            var calledMails = 0
            if let msgs = msg {
                let dispatchGroup = DispatchGroup()
                for m in msgs.reversed() {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    dispatchGroup.enter()

                    let op = self.IMAPSession.fetchParsedMessageOperation(withFolder: folderPath, uid: message.uid)
                    op?.start { err, data in self.parseMail(err, parser: data, message: message, record: record, folderPath: folderPath, newMailCallback: newMailCallback)
                        dispatchGroup.leave()
                    }
                    calledMails += 1
                    if calledMails > maxLoad {
                        break
                    }
                }
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    self.IMAPSession.disconnectOperation().start({ _ in })
                    completionCallback(false)
                }
            }
        }
    }

    private func parseMail(_ error: Error?, parser: MCOMessageParser?, message: MCOIMAPMessage, record: KeyRecord?, folderPath: String, newMailCallback: (() -> ())?) {
        guard error == nil else {
            print("Error while fetching mail: \(String(describing: error))")
            return
        }

        var rec: [MCOAddress] = []
        var cc: [MCOAddress] = []

        let header = message.header
        
        if header?.from == nil {
            // Drops mails with no from field. Otherwise it becomes ugly with no ezcontact,fromadress etc.
            return
        }

        var autocrypt: AutocryptContact? = nil
        var newKeyIds = [String]()
        if let _ = header?.extraHeaderValue(forName: AUTOCRYPTHEADER) {
            autocrypt = AutocryptContact(header: header!)
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
            let html: String
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
                if at.mimeType == "application/octet-stream", let content = String(data: at.data, encoding: String.Encoding.utf8), content.hasPrefix("-----BEGIN PGP PUBLIC KEY BLOCK-----") && (content.hasSuffix("-----END PGP PUBLIC KEY BLOCK-----") || content.hasSuffix("-----END PGP PUBLIC KEY BLOCK-----\n")) {
                    let pgp = SwiftPGP()
                    let keyId = pgp.importKeys(key: content, isSecretKey: false, autocrypt: false)
                    newKeyIds.append(contentsOf: keyId)
                }
                if at.mimeType == "application/pgp-keys" {
                    let pgp = SwiftPGP()
                    let keyIds = pgp.importKeys(data: at.data, secret: false)
                    newKeyIds.append(contentsOf: keyIds)
                }
            }
            if isEnc {
                html = msgParser!.plainTextBodyRenderingAndStripWhitespace(false)

                lineArray = html.components(separatedBy: "\n")
                body = lineArray.joined(separator: "\n")
                body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                body.append("\n")
                dec = decryptText(body: body, from: message.header.from, autocrypt: autocrypt)
                if (dec?.plaintext != nil) {
                    msgParser = MCOMessageParser(data: dec?.decryptedData)
                    body = msgParser!.plainTextBodyRenderingAndStripWhitespace(false)
                }
            } else {
                html = msgParser!.plainTextRendering()
                
                lineArray = html.components(separatedBy: "\n")
                lineArray.removeFirst(4)
                body = lineArray.joined(separator: "\n")
                body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                body.append("\n")
                
                if let chipher = findInlinePGP(text: body){
                    dec = decryptText(body: chipher, from: message.header.from, autocrypt: autocrypt)
                    if dec != nil{
                        if let text = dec?.decryptedText {
                            body = text
                        }
                    }
                }
            }
            
            
            if let header = header, let from = header.from, let date = header.date {
                let mail = DataHandler.handler.createMail(UInt64(message.uid), sender: from, receivers: rec, cc: cc, time: date, received: true, subject: header.subject ?? "", body: body, flags: message.flags, record: record, autocrypt: autocrypt, decryptedData: dec, folderPath: folderPath)
                
                let pgp = SwiftPGP()
                if let autoc = autocrypt{
                    let publickeys = pgp.importKeys(key: autoc.key, isSecretKey: false, autocrypt: true)
                    for pk in publickeys{
                        _ = DataHandler.handler.newPublicKey(keyID: pk, cryptoType: CryptoScheme.PGP, adr: from.mailbox, autocrypt: true, firstMail: mail)
                        
                    }
                }
                for keyId in newKeyIds{
                    _ = DataHandler.handler.newPublicKey(keyID: keyId, cryptoType: CryptoScheme.PGP, adr: from.mailbox, autocrypt: false, firstMail: mail)
                }
                if newMailCallback != nil{
                    newMailCallback!()
                }
            }
        }
    }

    private func findInlinePGP(text: String) -> String?{
        var range = text.range(of: "-----BEGIN PGP MESSAGE-----")
        if let lower = range?.lowerBound {
            range = text.range(of: "-----END PGP MESSAGE-----")
            if let upper = range?.upperBound {
                let retValue = text.substring(to: upper).substring(from: lower)
                return retValue
            }
        }
        return nil
    }
    
    private func decryptText(body: String, from: MCOAddress?, autocrypt: AutocryptContact?) -> CryptoObject? {
        if let data = body.data(using: String.Encoding.utf8, allowLossyConversion: true) as Data?, let sender = from?.mailbox {
            let pgp = SwiftPGP()
            var keyIds = [String]()
            if let adr = DataHandler.handler.findMailAddress(adr: sender){
                if let keys = adr.key{
                    for k in keys{
                        let key = k as! PersistentKey
                        keyIds.append(key.keyID)
                    }
                }
            }
            if let a = autocrypt{
                let key = pgp.importKeys(key: a.key, isSecretKey: false, autocrypt: true)
                keyIds.append(contentsOf: key)
            }
            let secretkeys = DataHandler.handler.findSecretKeys()
            var decId: String? = nil
            for s in secretkeys{
                if !s.obsolete{
                    decId = s.keyID
                    break
                }
            }
            
            return pgp.decrypt(data: data, decryptionId: decId, verifyIds: keyIds)
            
        }
       
        return nil
    }
   

    func checkSMTP(_ completion: @escaping (Error?) -> Void) {
        let useraddr = UserManager.loadUserValue(Attribute.userAddr) as! String
        let username = UserManager.loadUserValue(Attribute.userName) as! String

        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = username
        session.password = UserManager.loadUserValue(Attribute.userPW) as! String
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
            op?.start({ _ in self.move(mails: mails, from: from, to: to, folderCreated: true)})
        }
        else {
            for mail in mails {
                uids.add(mail.uid)
                mail.folder.removeFromMails(mail)
                DataHandler.handler.delete(mail: mail)
            }
            let op = self.IMAPSession.moveMessagesOperation(withFolder: from, uids: uids, destFolder: to)
            op?.start{
                (err, vanished) -> Void in
                guard err == nil else {
                    print("Error while moving mails: \(String(describing: err))")
                    return
                }
            }
        }
    }
    
    
    func allFolders(_ completion: @escaping (Error?, [Any]?) -> Void){
    
        let op = IMAPSession.fetchAllFoldersOperation()
        op?.start(completion)
    }
    
    
    func initFolder(folder: Folder, newMailCallback: @escaping (() -> ()),completionCallback: @escaping ((Bool) -> ())){
        let folderPath = folder.path//UserManager.convertToBackendFolderPath(from: folder.path)
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        let toFetchIDs  = MCOIndexSet()
       
        
        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching \(folderPath): \(String(describing: err))")
                completionCallback(true)
                return
            }
            if let msgs = msg {
                folder.lastUpdate = Date()
                for m in msgs {
                    if let message = m as? MCOIMAPMessage{
                        toFetchIDs.add(UInt64(message.uid))
                    }
                }
                self.loadMessagesFromServer(toFetchIDs, folderPath: folderPath, maxLoad: 50, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
            }
            else{
                completionCallback(true)
            }
        }
    }
    
    func initInbox(inbox: Folder, newMailCallback: @escaping (() -> ()),completionCallback: @escaping ((Bool) -> ()) ){
        if let date = Calendar.current.date(byAdding: .month, value: -1, to: Date()){
            loadMailsSinceDate(folder: inbox, since: date, maxLoad: 200, newMailCallback: newMailCallback, completionCallback: completionCallback)
        }
        else{
            print("No date for init inbox!")
            initFolder(folder: inbox, newMailCallback: newMailCallback, completionCallback: completionCallback)
        }
        
    }
    
    func updateFolder(folder: Folder, newMailCallback: @escaping (() -> ()),completionCallback: @escaping ((Bool) -> ())){
        if let date = folder.lastUpdate{
            loadMailsSinceDate(folder: folder, since: date, newMailCallback: newMailCallback, completionCallback: completionCallback)
        }
        else{
            if folder.path == UserManager.backendInboxFolderPath || folder.path == "INBOX" || folder.path == "Inbox"{
                initInbox(inbox: folder, newMailCallback: newMailCallback, completionCallback: completionCallback)
            }
            else{
                initFolder(folder: folder, newMailCallback: newMailCallback, completionCallback: completionCallback)
            }
        }
    }
    
    func olderMails(folder: Folder, newMailCallback: @escaping (() -> ()),completionCallback: @escaping ((Bool) -> ())){
        let folderPath = UserManager.convertToBackendFolderPath(from: folder.path)
        if let mails = folder.mails{
            var oldestDate:Date?
            for m in mails{
                if let mail = m as? PersistentMail{
                    if oldestDate == nil || mail.date < oldestDate{
                        oldestDate = mail.date
                    }
                }
            }
            if let date = oldestDate{
                let searchExp = MCOIMAPSearchExpression.search(before: date)
                let searchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folderPath, expression: searchExp)
                
                searchOperation?.start{(err, uids)-> Void in
                    guard err == nil else{
                        print("Error while searching inbox: \(String(describing: err))")
                        completionCallback(true)
                        return
                    }
                    if let ids = uids{
                        folder.lastUpdate = Date()
                        self.loadMessagesFromServer(ids, folderPath: folderPath, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
                    }
                    else{
                        completionCallback(true)
                    }
                }
            }
            else{
                initFolder(folder: folder, newMailCallback: newMailCallback, completionCallback: completionCallback)
            }
        }
        else{
            initFolder(folder: folder, newMailCallback: newMailCallback, completionCallback: completionCallback)
        }
    
    }
    
    
    private func loadMailsSinceDate(folder: Folder, since: Date, maxLoad: Int = MailHandler.MAXMAILS, newMailCallback: @escaping (() -> ()),completionCallback: @escaping ((Bool) -> ())){
        let folderPath = UserManager.convertToBackendFolderPath(from: folder.path)
        let searchExp = MCOIMAPSearchExpression.search(since: since)
        let searchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folderPath, expression: searchExp)
        
        searchOperation?.start{(err, uids)-> Void in
            guard err == nil else{
                completionCallback(true)
                return
            }
            if let ids = uids{
                folder.lastUpdate = Date()
                self.loadMessagesFromServer(ids, folderPath: folderPath, maxLoad: maxLoad, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
            }
            else{
                completionCallback(true)
            }
        }

    }
}
