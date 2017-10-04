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

    fileprivate static let MAXMAILS: UInt32 = 50

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
                builder.textBody = "Dies ist verschlüsselt!"
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
        imapsession.authType = UserManager.loadImapAuthType()//MCOAuthType(rawValue: UserManager.loadUserValue(Attribute.imapAuthType) as! Int) //MCOAuthType.SASLPlain
        imapsession.connectionType = MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.imapConnectionType) as! Int)//MCOConnectionType.TLS
        
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
                let op = IMAPIdleSession!.idleOperation(withFolder: "INBOX", lastKnownUID: UInt32(DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath).maxID))
                op?.start({ error in
                    guard error == nil else {
                        print("An error occured with the idle operation: \(String(describing: error))")
                        return
                    }

                    print("Something happened while idleing!")
                    self.IMAPIdleSession = nil
                    self.receiveAll(newMailCallback: addNewMail, completionCallback: { _ in self.startIMAPIdleIfSupported(addNewMail: addNewMail) })
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
        session.authType = UserManager.loadSmtpAuthType()//MCOAuthType(rawValue: UserManager.loadUserValue(Attribute.smtpAuthType) as! Int)
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

    func firstLookUp(_ folderPath: String, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        /*findMaxUID(folderPath){max in
            var uids: MCOIndexSet
            print("Max uid: \(max)")
            var (min, overflow) = UInt64.subtractWithOverflow(max, UInt64(MailHandler.MAXMAILS))
            if min <= 0 || overflow {
                min = 1
            }
            uids = MCOIndexSet(range: MCORangeMake(min, UInt64(MailHandler.MAXMAILS))) // DataHandler.handler.maxUID
            print("call for #\(uids.count()) uids \(uids.rangesCount()); min \(min); max \(max)")
            uids.remove(DataHandler.handler.findFolder(with: folderPath).uids)
            self.loadMessagesFromServer(uids, folderPath: folderPath, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
        
        }*/
        getUIDs(for: folderPath) {allUIDs in
            let loadUIDs = allUIDs.suffix(Int(MailHandler.MAXMAILS))
            if let last = loadUIDs.last, let first = loadUIDs.first {
                let indexSet = MCOIndexSet(range: MCORange.init(location: first, length: last-first))
                if indexSet != nil {
                    indexSet!.remove(DataHandler.handler.findFolder(with: folderPath).uids)
                    self.loadMessagesFromServer(indexSet!, folderPath: folderPath, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
                    return
                }
            }
            completionCallback(true)
            return
        }
    }
    
    //olderMails from mergeFolders branch
    func olderMails(with folderPath: String, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        var uids: MCOIndexSet
        let myfolder = DataHandler.handler.findFolder(with: folderPath)
        
        if myfolder.maxID <= 1{
            return firstLookUp(folderPath, newMailCallback: newMailCallback, completionCallback: completionCallback)
        }
        print("look for more mails: \(myfolder.lastID) to \(myfolder.maxID)")
        
        uids = MCOIndexSet(range: MCORangeMake(myfolder.lastID, myfolder.maxID))
        uids.remove(myfolder.uids)
        
        self.loadMessagesFromServer(uids, folderPath: folderPath, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
    }

    func receiveAll(_ folderPath: String = "INBOX", newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        print("Call all mails!")
        getUIDs(for: folderPath) {uids in
            print("We have all uids! let make progress!")
            let loadUIDs = uids.filter{$0 > DataHandler.handler.findFolder(with: folderPath).maxID}
            if let last = loadUIDs.last, let first = loadUIDs.first {
                if let indexSet = MCOIndexSet(range: MCORange.init(location: first, length: last-first)) {
                    print("Load messages!")
                    self.loadMessagesFromServer(indexSet, folderPath: folderPath, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
                }
            }
        }
    }

    func loadMoreMails(_ record: KeyRecord, folderPath: String, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
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
                if var setOfIndices = ids {
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

    func loadMessagesFromServer(_ uids: MCOIndexSet, folderPath: String, maxLoad: UInt32 = MailHandler.MAXMAILS,record: KeyRecord?, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue)

        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = [AUTOCRYPTHEADER]
        
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(String(describing: err))")
                completionCallback(true)
                return
            }
            var calledMails: UInt32 = 0
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

    func parseMail(_ error: Error?, parser: MCOMessageParser?, message: MCOIMAPMessage, record: KeyRecord?, folderPath: String, newMailCallback: (() -> ())) {
        guard error == nil else {
            print("Error while fetching mail: \(String(describing: error))")
            return
        }

        var rec: [MCOAddress] = []
        var cc: [MCOAddress] = []

        let header = message.header

        var autocrypt: AutocryptContact? = nil
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

            if header?.from == nil {
                // Drops mails with no from field. Otherwise it becomes ugly with no ezcontact,fromadress etc.
                return
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

                newMailCallback()
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


    fileprivate func cutIndexSet(_ inputSet: MCOIndexSet, maxMails: UInt32 = MAXMAILS) -> MCOIndexSet {
        let max = maxMails
        if inputSet.count() <= max {
            return inputSet
        }
        let result = MCOIndexSet()
        for x in inputSet.nsIndexSet().reversed() {
            if result.count() < max {
                result.add(UInt64(x))
            }
            else{
                break
            }
        }
        return result
    }


    func findMaxUID(_ folder: String, callback: @escaping ((_ maxUID: UInt64) -> ())) {
        //TODO: NSP!!!
        var maxUID: UInt64 = 0
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folder, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(String(describing: err))")
                return
            }
            if let msgs = msg {
                for m in msgs {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    let id = UInt64(message.uid)
                    if id > maxUID {
                        maxUID = id
                    }
                }
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            callback(maxUID)
        }
    }
    
    func getUIDs(for folderPath: String, callback: @escaping ((_ uids: [UInt64]) -> ())) {
        //TODO: NSP!!!
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        var ids: [UInt64] = []
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(String(describing: err))")
                return
            }
            if let msgs = msg {
                for m in msgs {
                    if let message: MCOIMAPMessage = m as? MCOIMAPMessage {
                        if !DataHandler.handler.hasMail(folderName: folderPath, uid: UInt64(message.uid)){
                            ids.append(UInt64(message.uid))
                        }
                    }
                    if ids.count > Int(MailHandler.MAXMAILS){
                        print("Toooo man ids! #ids: \(ids.count) \n \(ids)")
                        break
                    }
                }
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            callback(ids.sorted())
        }
    }

    func checkSMTP(_ completion: @escaping (Error?) -> Void) {
        let useraddr = UserManager.loadUserValue(Attribute.userAddr) as! String
        let username = UserManager.loadUserValue(Attribute.userName) as! String

        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = username
        session.password = UserManager.loadUserValue(Attribute.userPW) as! String
        session.authType = UserManager.loadSmtpAuthType()//MCOAuthType.init(rawValue: UserManager.loadUserValue(Attribute.smtpAuthType) as! Int)//MCOAuthType.SASLPlain
        session.connectionType = MCOConnectionType.init(rawValue: UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int)//MCOConnectionType.StartTLS

        session.checkAccountOperationWith(from: MCOAddress.init(mailbox: useraddr)).start(completion)

    }

    func checkIMAP(_ completion: @escaping (Error?) -> Void) {
        self.setupIMAPSession().checkAccountOperation().start(completion/* as! (Error?) -> Void*/)
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
    
    /*func delete(mails: [PersistentMail]) {
        for mail in mails {
            DataHandler.handler.deleteMail(with: mail.uid)
        }
    }*/
    
    func allFolders(_ completion: @escaping (Error?, [Any]?) -> Void){
    
        let op = IMAPSession.fetchAllFoldersOperation()
        op?.start(completion)
    }
}
