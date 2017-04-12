//
//  MailHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 22.08.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//


/*
 TODO:
 get  MaxUID from server
 Load new Messages
 (Paramete: none, person, threadID, Mailbox, #Mails)
 Load older messages
 (Paramete: none, person, threadID, Mailbox, #Mails)

 
 load for spefic thread -> thread ID, see: https://github.com/MailCore/mailcore2/issues/555
 
 Detect encrypted messages
 Autocryptmessages
 
 
 */


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
let TO = "to"
let TYPE = "type"
let ENCRYPTION = "prefer-encrypted"
let KEY = "key"


class AutocryptContact {
    var addr: String = ""
    var type: EncryptionType = .PGP
    var prefer_encryption: Bool = true
    var key: String = ""

    init(addr: String, type: String, prefer_encryption: String, key: String) {
        self.addr = addr
        self.type = EncryptionType.typeFromAutocrypt(type)
        setPrefer_encryption(prefer_encryption)
        self.key = key
    }


    convenience init(header: MCOMessageHeader) {
        let autocrypt = header.extraHeaderValue(forName: AUTOCRYPTHEADER)
        var field: [String]
        var addr = ""
        var type = "p" // Default value since no one else uses autocrypt...
        var pref = "true"
        var key = ""

        if(autocrypt != nil) {
            let autocrypt_fields = autocrypt?.components(separatedBy: ";")
            for f in autocrypt_fields! {
                field = f.components(separatedBy: "=")
                if field.count > 1 {
                    let flag = field[0].trimmingCharacters(in: CharacterSet.whitespaces)
                    var value = field[1]
                    if field.count > 2 {
                        for i in 2...(field.count - 1) {
                            value = value + "="
                            value = value + field[i]
                        }
                    }
                    switch flag {
                    case TO:
                        addr = value
                        break
                    case TYPE:
                        type = value
                        break
                    case ENCRYPTION:
                        pref = value
                        break
                    case KEY:
                        if value.characters.count > 0{
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
        if addr != "" && type != .unknown && key != "" {
            return true
        }
        return false
    }

    func setPrefer_encryption(_ input: String) -> Bool {
        if input == "yes" || input == "YES" || input == "Yes" {
            prefer_encryption = true
            return true
        }
            else if input == "no" || input == "NO" || input == "No" {
            prefer_encryption = false
            return true
        }
        return false
    }

    func toString() -> String {
        return "Addr: \(addr) | type: \(type) | encryption? \(prefer_encryption) | key: \(key)"
    }
}

class MailHandler {

    var delegate: MailHandlerDelegator?

    fileprivate static let MAXMAILS: Int = 10



    fileprivate let concurrentMailServer = DispatchQueue(
                                                             label: "com.enzevalos.mailserverQueue", attributes: DispatchQueue.Attributes.concurrent)

    var IMAPSes: MCOIMAPSession?

    var IMAPSession: MCOIMAPSession {
        get {
            if IMAPSes == nil {
                setupIMAPSession()
            }

            return IMAPSes!
        }
    }


    //TODO: signatur hinzufügen


    func add_autocrypt_header(_ builder: MCOMessageBuilder) {
        let adr = UserManager.loadUserValue(Attribute.userAddr) as! String
        let pgpenc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP) as! PGPEncryption
        builder.header.setExtraHeaderValue(pgpenc.autocryptHeader(adr), forName: AUTOCRYPTHEADER)
    }
    
    fileprivate func createHeader(_ builder: MCOMessageBuilder, toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String){
        
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
        
        add_autocrypt_header(builder)
    
    }

    //return if send successfully
    func send(_ toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, callback: @escaping (Error?) -> Void) {
        //http://stackoverflow.com/questions/31485359/sending-mailcore2-plain-emails-in-swift

        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        let session = createSMTPSession()
        let builder = MCOMessageBuilder()

        createHeader(builder, toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject)
        

        // MailAddresses statt strings??

        var allRec: [String] = []
        allRec.append(contentsOf: toEntrys)
        allRec.append(contentsOf: ccEntrys)
        // What about BCC??

        //TODO add support for different Encryptions here
        //edit sortMailaddressesByEncryptionMCOAddress and sortMailaddressesByEncryption because a mailaddress can be found in multiple Encryptions
        let ordered = EnzevalosEncryptionHandler.sortMailaddressesByEncryptionMCOAddress(allRec)

        let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)

        var encryption: Encryption
        var sendData: Data
        let orderedString = EnzevalosEncryptionHandler.sortMailaddressesByEncryption(allRec)
        var sendOperation: MCOSMTPSendOperation

        //TODO: Consider pref enc = false
        
        if let encPGP = ordered[EncryptionType.PGP] {
            encryption = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)!
            if let encData = encryption.signAndEncrypt("\n"+message, mailaddresses: orderedString[EncryptionType.PGP]!) { //ohne "\n" wird der erste Teil der Nachricht, bis sich ein einzelnen \n in einer Zeile befindet nicht in die Nachricht getan
                //sendData = encData
                builder.textBody = String(data: encData, encoding: String.Encoding.utf8)
                sendData = builder.data()
                sendOperation = session.sendOperation(with: sendData, from: userID, recipients: encPGP)
                //sendOperation = session.sendOperationWithData(builder.openPGPEncryptedMessageDataWithEncryptedData(sendData), from: userID, recipients: encPGP)
                //TODO handle different callbacks
                sendOperation.start(callback)
                builder.textBody = message
            }
                else {
                //TODO do it better
                callback(NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError, userInfo: nil))
            }
        }

        if let unenc = ordered[EncryptionType.unknown] {
            builder.textBody = message
            sendData = builder.data()
            sendOperation = session.sendOperation(with: sendData, from: userID, recipients: unenc)
            //TODO handle different callbacks
            sendOperation.start(callback)
        }
    }

    func setupIMAPSession() {
        let imapsession = MCOIMAPSession()
        imapsession.hostname = UserManager.loadUserValue(Attribute.imapHostname) as! String
        imapsession.port = UInt32(UserManager.loadUserValue(Attribute.imapPort) as! Int)
        imapsession.username = UserManager.loadUserValue(Attribute.userAddr) as! String
        imapsession.password = UserManager.loadUserValue(Attribute.userPW) as! String
        imapsession.authType = MCOAuthType(rawValue: UserManager.loadUserValue(Attribute.imapAuthType) as! Int) //MCOAuthType.SASLPlain
        imapsession.connectionType = MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.imapConnectionType) as! Int)//MCOConnectionType.TLS
        self.IMAPSes = imapsession
    }
    
    fileprivate func createSMTPSession()-> MCOSMTPSession{
        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        session.password = UserManager.loadUserValue(Attribute.userPW) as! String
        session.authType = MCOAuthType(rawValue: UserManager.loadUserValue(Attribute.smtpAuthType) as! Int)
        session.connectionType = MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int)
        return session
    }



    func addFlag(_ uid: UInt64, flags: MCOMessageFlag, folder: String = "INBOX") {
        let op = self.IMAPSession.storeFlagsOperation(withFolder: folder, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.set, flags: flags)
        op?.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            }
        }
    }

    func removeFlag(_ uid: UInt64, flags: MCOMessageFlag, folder: String = "INBOX") {
        let op = self.IMAPSession.storeFlagsOperation(withFolder: folder, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.remove, flags: flags)

        op?.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            } else {
                print("Succsessfully updated flags!")
            }
        }
    }


    func receiveAll(_ folder: String = "INBOX", newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        let uids: MCOIndexSet
        uids = MCOIndexSet(range: MCORangeMake(DataHandler.handler.maxUID, UINT64_MAX))
        loadMessagesFromServer(uids, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
    }

    func loadMoreMails(_ record: KeyRecord, folder: String = "INBOX", newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        let addresses: [MailAddress]
        addresses = record.addresses

        for adr in addresses {
            let searchExpr: MCOIMAPSearchExpression = MCOIMAPSearchExpression.search(from: adr.mailAddress)
            let searchOperation: MCOIMAPSearchOperation = self.IMAPSession.searchExpressionOperation(withFolder: folder, expression: searchExpr)

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
                    print("Size first: \(setOfIndices.count())")
                    setOfIndices = self.cutIndexSet(setOfIndices)
                    print("Size first: \(setOfIndices.count())")

                    self.loadMessagesFromServer(setOfIndices, record: record, newMailCallback: newMailCallback, completionCallback: completionCallback)
                }
            }
        }
    }

    func loadMessagesFromServer(_ uids: MCOIndexSet, folder: String = "INBOX", record: KeyRecord?, newMailCallback: @escaping (() -> ()), completionCallback: @escaping ((_ error: Bool) -> ())) {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue | MCOIMAPMessagesRequestKind.flags.rawValue)
        let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folder, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = [AUTOCRYPTHEADER]
        
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(err)")
                completionCallback(true)
                return
            }
            if let msgs = msg {
                let dispatchGroup = DispatchGroup()
                for m in msgs {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    dispatchGroup.enter()

                    let op = self.IMAPSession.fetchParsedMessageOperation(withFolder: folder, uid: message.uid)
                    op?.start { err, data in self.parseMail(err, parser: data, message: message, record: record, newMailCallback: newMailCallback)
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    self.IMAPSession.disconnectOperation().start({ _ in })
                    completionCallback(false)
                }
            }
        }
    }
func parseMail(_ error: Error?, parser: MCOMessageParser?, message: MCOIMAPMessage, record: KeyRecord?, newMailCallback: (() -> ())) {
      guard error == nil else {
            print("Error while fetching mail: \(error)")
            return
        }
        if let data = parser?.data() {
            let msgParser = MCOMessageParser(data: data)

            let html: String = msgParser!.plainTextRendering()
            var lineArray = html.components(separatedBy: "\n")
           
            lineArray.removeFirst(4)
            var body = lineArray.joined(separator: "\n")
            body = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            body.append("\n")
            var rec: [MCOAddress] = []
            var cc: [MCOAddress] = []

            let header = message.header
            var autocrypt: AutocryptContact? = nil
            if let _ = header?.extraHeaderValue(forName: AUTOCRYPTHEADER){
                autocrypt = AutocryptContact(header: header!)
                print(autocrypt?.toString() ?? "nil")
                if(autocrypt?.type == EncryptionType.PGP && autocrypt?.key.characters.count > 0){
                    let pgp = ObjectivePGP.init()
                    pgp.importPublicKey(fromHeader: (autocrypt?.key)!, allowDuplicates: false)
                    let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                    do {
                        let pgpKey = try pgp.keys[0].export()
                        enc?.addKey(pgpKey, forMailAddresses: [(header?.from.mailbox)!])
                    }
                    catch {
                        print("Could not conntect key! \(autocrypt?.toString())")
                    }
                }
                
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

            DataHandler.handler.createMail(UInt64(message.uid), sender: (header?.from)!, receivers: rec, cc: cc, time: (header?.date)!, received: true, subject: header?.subject ?? "", body: body, flags: message.flags, record: record, autocrypt: autocrypt) //@Olli: fatal error: unexpectedly found nil while unwrapping an Optional value //crash wenn kein header vorhanden ist
            newMailCallback()
        }
    }


    fileprivate func cutIndexSet(_ inputSet: MCOIndexSet, maxMails: Int = MAXMAILS) -> MCOIndexSet {
        let max = UInt32(maxMails)
        if inputSet.count() <= max {
            return inputSet
        }
        let result = MCOIndexSet()
        for x in inputSet.nsIndexSet().reversed() {
            if(result.count() < max) {
                result.add(UInt64(x))
            }
        }
        return result
    }


    func findMaxUID(_ folder: String = "INBOX", callback: @escaping ((_ maxUID: UInt64) -> ())) {
        //TODO: NSP!!!
        var maxUID: UInt64 = 0
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(0, UINT64_MAX))
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperation(withFolder: folder, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(err)")
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

    func checkSMTP(_ completion: @escaping (Error?) -> Void) {
        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        let username = UserManager.loadUserValue(Attribute.userName) as! String
        
        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.smtpHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.smtpPort) as! Int)
        session.username = username
        session.password = UserManager.loadUserValue(Attribute.userPW) as! String
        session.authType = MCOAuthType.init(rawValue: UserManager.loadUserValue(Attribute.smtpAuthType) as! Int)//MCOAuthType.SASLPlain
        session.connectionType = MCOConnectionType.init(rawValue: UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int)//MCOConnectionType.StartTLS
        
        session.checkAccountOperationWith(from: MCOAddress.init(mailbox: useraddr)).start(completion)
        
    }
    
    func checkIMAP(_ completion: @escaping (Error?) -> Void) {
        self.setupIMAPSession()
        
        self.IMAPSession.checkAccountOperation().start(completion/* as! (Error?) -> Void*/)
        self.IMAPSession.connectOperation().start(completion/* as! (Error?) -> Void*/)
    }
    
    
    
}
