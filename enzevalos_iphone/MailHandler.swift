 //
//  MailHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 22.08.16.
//  //  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

class MailHandler {
    private static let MAXMAILS = 25

    var delegate: MailHandlerDelegator?
    var INBOX: String {
        return "INBOX"
    }
    private let concurrentMailServer = DispatchQueue(label: "com.enzevalos.mailserverQueue", attributes: DispatchQueue.Attributes.concurrent) //TODO: REMOVE?
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
    
    func sendSecretKey(keyID: String, key: String, passcode: String, callback: @escaping (Error?) -> Void) {
        let mail = OutgoingMail.createSecretKeyExportMail(keyID: keyID, keyData: key, passcode: passcode)
        sendSMTP(mail: mail, callback: callback)
    }
    
    func sendSMTP(mail: OutgoingMail, callback: ((Error?) -> Void)?) {
        // Problem: Body bei verschlüsselter Mail auf Mac fehlt und flags falsch?‚
        let session = createSMTPSession()
        var sent = false
        if let callback = callback, mail.encReceivers.count > 0 {
            let data = mail.pgpData
            if let sendOperation = session.sendOperation(with: data, from: mail.sender, recipients: mail.encReceivers){
                sendOperation.start(callback) //TODO: ERROR HANDLING? -> Jakob IDEE: Funktion mit callback, operation und function call. -> Dann zentrale Fehlerbehandlung
                sent = true
            }
        }
        if let callback = callback, mail.plainReceivers.count > 0 {
            if let sendOperation = session.sendOperation(with: mail.plainData, from: mail.sender, recipients: mail.plainReceivers) {
                sendOperation.start(callback) //TODO: ERROR HANDLING? -> Jakob
                sent = true
            }
        }
        if sent {
            _ = mail.logMail()
        }
        else {
            callback!(nil)
        }
    }
    
    func storeIMAP(mail: OutgoingMail, folder: String, callback: ((Error?) -> Void)?) {
        // 1. Test if folder exists
        // TODO: Does this really work? Should we test if folder exits on server and not locally? -> Ask Jakob
        if !DataHandler.handler.existsFolder(with: folder) {
            if let op = IMAPSession.createFolderOperation(folder) {
                op.start({ error in
                    guard error == nil else {
                        self.errorhandling(error: error, originalCall: {self.storeIMAP(mail: mail, folder: folder, callback: callback)}, completionCallback: callback)
                        return
                    }
                    // Create folder on local
                    _ = DataHandler.handler.findFolder(with: folder)
                    self.storeIMAP(mail: mail, folder: folder, callback: callback)
                })
            }
        }
        else {
            // 2. Store Mail in test
            // We can always store encrypted data on the imap server because the user has a key pair and it is users imap account.
            let op = self.IMAPSession.appendMessageOperation(withFolder: folder, messageData: mail.pgpData, flags: MCOMessageFlag.mdnSent)
            op?.start({ error, _ in
                guard error == nil else {
                    self.errorhandling(error: error, originalCall: {self.storeIMAP(mail: mail, folder: folder, callback: callback)}, completionCallback: callback)
                    return
                }
                if let callback = callback {
                    callback(nil)
                }
            })
        }
    }
    
    func send(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, sendEncryptedIfPossible: Bool = true, callback: @escaping (Error?) -> Void, loggingMail: Bool = false, htmlContent: String? = nil, warningReact: Bool = false, inviteMail: Bool = false, textparts: Int = 0) {
        let mail: OutgoingMail
        if inviteMail {
            mail = OutgoingMail.createInvitationMail(toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, textContent: message, htmlContent: htmlContent)
        }
        else {
            mail = OutgoingMail(toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, textContent: message, htmlContent: htmlContent, textparts: textparts, sendEncryptedIfPossible: sendEncryptedIfPossible)
        }
        self.sendSMTP(mail: mail, callback: {error in
            guard error == nil else {
                callback(error)
                return
            }
            _ = mail.logMail()
            var copyFolder = UserManager.backendSentFolderPath
            if loggingMail {
                copyFolder = UserManager.loadUserValue(.loggingFolderPath) as! String
            }
            self.storeIMAP(mail: mail, folder: copyFolder, callback: callback)
        })
    }

    func createDraft(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, callback: @escaping (Error?) -> Void) {
        let mail = OutgoingMail.createDraft(toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject, textContent: message, htmlContent: nil)
        let folder = UserManager.backendDraftFolderPath
        self.storeIMAP(mail: mail, folder: folder, callback: callback)
        _ = mail.logMail()
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
    //TODO: REMOVE and ADD FLAG mergen

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
    
    func newMails(completionCallback: @escaping (_ newMails: UInt32, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void)  -> (), performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
        let folder = DataHandler.handler.findFolder(with: INBOX)
        let folderstatus = IMAPSession.folderStatusOperation(folder.path)
        print("Ask folder")
        var backgroundTaskID: Int?
        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue")
            backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks"){
                UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                backgroundTaskID = UIBackgroundTaskInvalid
            }
            
            folderstatus?.start { (error, status) -> Void in
                print("Result!")
                guard error == nil else {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                    backgroundTaskID = UIBackgroundTaskInvalid
                    completionCallback(0, completionHandler)
                    return
                }
                if let status = status {
                    let uidValidity = status.uidValidity
                    let uid = status.uidNext
                    let newMails = status.recentCount
                    print("Status: ", status)
                    print("newMails: ", newMails)
                    let currentDateTime = Date()
                    print(currentDateTime, " Folder maxID: ", folder.maxID)
                    if (uidValidity != folder.uidvalidity || folder.maxID < uid - 1) {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                        backgroundTaskID = UIBackgroundTaskInvalid
                        completionCallback(newMails, completionHandler)
                    }
                    else {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                        backgroundTaskID = UIBackgroundTaskInvalid
                        completionCallback(0, completionHandler)
                    }
                }
            }
        }
    }

    private func loadMessagesFromServer(_ uids: MCOIndexSet, folderPath: String, maxLoad: Int = MailHandler.MAXMAILS, record: KeyRecord?, completionCallback: @escaping ((_ error: Error?) -> ())) {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue)
        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folderPath, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = Autocrypt.EXTRAHEADERS
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
                        if let parser = data {
                            _ = self.parseMail(parser: parser, record: record, folderPath: folderPath, uid: UInt64(message.uid), flags: message.flags)

                        }
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

    internal func parseMail(parser: MCOMessageParser, record: KeyRecord?, folderPath: String, uid: UInt64, flags: MCOMessageFlag) -> PersistentMail?{
        var rec: [MCOAddress] = []
        var cc: [MCOAddress] = []
        var autocrypt: Autocrypt? = nil
        var newKeyIds = [String]()
        var secretKey: String? = nil
        var isEnc = false
        var html: String
        var body: String
        var lineArray: [String]
        var dec: CryptoObject? = nil
        let header = parser.header
        let msgID = header?.messageID
        let userAgent = header?.userAgent
        var references = [String]()
        
        // 1. parse header
        if header?.from == nil {
            // Drops mails with no from field. Otherwise it becomes ugly with no ezcontact,fromadress etc.
            return nil
        }
        if let refs = header?.references {
            for ref in refs {
                if let string = ref as? String {
                    references.append(string)
                }
            }
        }
        
        if let _ = header?.extraHeaderValue(forName: Autocrypt.AUTOCRYPTHEADER) {
            autocrypt = Autocrypt(header: header!)
        }
        if let _ = header?.extraHeaderValue(forName: Autocrypt.SETUPMESSAGE) {
            // TODO: Distinguish between other keys (future work)
            return nil
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
        
        // 2. parse body
        if let p = MCOMessageParser(data: parser.data()) {
            var msgParser = p
            for a in (msgParser.attachments())! {
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
                html = msgParser.plainTextRendering()
                lineArray = html.components(separatedBy: "\n")
                lineArray.removeFirst(4)
                body = lineArray.joined(separator: "\n")
                body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                body.append("\n")
                dec = decryptText(body: body, from: header?.from, autocrypt: autocrypt)
                if (dec?.plaintext != nil) {
                    msgParser = MCOMessageParser(data: dec?.decryptedData)
                    html = msgParser.plainTextBodyRenderingAndStripWhitespace(false)
                    lineArray = html.components(separatedBy: "\n")
                    body = lineArray.joined(separator: "\n")
                    body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    //body.append("\n")
                    for a in (msgParser.attachments())! {
                        let at = a as! MCOAttachment
                        newKeyIds.append(contentsOf: parsePublicKeys(attachment: at))
                        if let sk = parseSecretKey(attachment: at) {
                            secretKey = sk
                        }

                    }
                }
            } else {
                html = msgParser.plainTextBodyRendering() // statt nur plainText
                lineArray = html.components(separatedBy: "\n")
               // lineArray.removeFirst(4)
                body = lineArray.joined(separator: "\n")
                body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                // body.append("\n") //TODO: @ Jakob WHY????

                if let chipher = findInlinePGP(text: body) {
                    dec = decryptText(body: chipher, from: header?.from, autocrypt: autocrypt)
                    if dec != nil {
                        if let text = dec?.decryptedText {
                            body = text
                        }
                    }
                }
            }
        

            if let header = header, let from = header.from, let date = header.date {
                let mail = DataHandler.handler.createMail(uid, sender: from, receivers: rec, cc: cc, time: date, received: true, subject: header.subject ?? "", body: body, flags: flags, record: record, autocrypt: autocrypt, decryptedData: dec, folderPath: folderPath, secretKey: secretKey, references: references, mailagent: userAgent, messageID: msgID)
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
                    Logger.log(received: m)
                }
                return mail
            }
    }
        return nil
    }

    private func findInlinePGP(text: String) -> String? {
        var range = text.range(of: "-----BEGIN PGP MESSAGE-----")
        if let lower = range?.lowerBound {
            range = text.range(of: "-----END PGP MESSAGE-----")
            if let upper = range?.upperBound {
                let retValue = String(text[lower..<upper])
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
                        if let keyId = try? pgp.importKeys(key: String(pk), pw: nil, isSecretKey: false, autocrypt: false) {
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
                    let sk = String(content[s..<e])
                    return sk
                }
            }
        }
        return nil
    }

    private func decryptText(body: String, from: MCOAddress?, autocrypt: Autocrypt?) -> CryptoObject? {
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
                                self.errorhandling(error: err, originalCall: {self.move(mails: mails, from: from, to: to)}, completionCallback: { err in
                                    guard err != nil else {
                                        return
                                    }
                                    let op = self.IMAPSession.copyMessagesOperation(withFolder: from, uids: uids, destFolder: to)
                                    op?.start({error, _ in
                                        guard error == nil else {
                                            return
                                        }
                                        uids.enumerate({uid in
                                            self.addFlag(uid, flags: MCOMessageFlag.deleted, folder: from)
                                        })
                                    })
                                })
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
