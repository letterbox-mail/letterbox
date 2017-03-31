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
        let autocrypt = header.extraHeaderValueForName(AUTOCRYPTHEADER)
        var field: [String]
        var addr = ""
        var type = "p" // Default value since no one else uses autocrypt...
        var pref = "true"
        var key = ""

        if(autocrypt != nil) {
            let autocrypt_fields = autocrypt.componentsSeparatedByString(";")
            for f in autocrypt_fields {
                field = f.componentsSeparatedByString("=")
                if field.count > 1 {
                    let flag = field[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
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

    func setPrefer_encryption(input: String) -> Bool {
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

    private static let MAXMAILS: Int = 10



    private let concurrentMailServer = dispatch_queue_create(
                                                             "com.enzevalos.mailserverQueue", DISPATCH_QUEUE_CONCURRENT)

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


    func add_autocrypt_header(builder: MCOMessageBuilder) {
        let adr = UserManager.loadUserValue(Attribute.UserAddr) as! String
        let pgpenc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP) as! PGPEncryption
        builder.header.setExtraHeaderValue(pgpenc.autocryptHeader(adr), forName: AUTOCRYPTHEADER)
    }
    
    private func createHeader(builder: MCOMessageBuilder, toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String){
        
        let username = UserManager.loadUserValue(Attribute.UserName) as! String
        let useraddr = (UserManager.loadUserValue(Attribute.UserAddr) as! String)

    
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
    func send(toEntrys: [String], ccEntrys: [String], bccEntrys: [String], subject: String, message: String, callback: (NSError?) -> Void) {
        //http://stackoverflow.com/questions/31485359/sending-mailcore2-plain-emails-in-swift

        let useraddr = (UserManager.loadUserValue(Attribute.UserAddr) as! String)
        let session = createSMTPSession()
        let builder = MCOMessageBuilder()

        createHeader(builder, toEntrys: toEntrys, ccEntrys: ccEntrys, bccEntrys: bccEntrys, subject: subject)
        

        // MailAddresses statt strings??

        var allRec: [String] = []
        allRec.appendContentsOf(toEntrys)
        allRec.appendContentsOf(ccEntrys)
        // What about BCC??

        //TODO add support for different Encryptions here
        //edit sortMailaddressesByEncryptionMCOAddress and sortMailaddressesByEncryption because a mailaddress can be found in multiple Encryptions
        let ordered = EnzevalosEncryptionHandler.sortMailaddressesByEncryptionMCOAddress(allRec)

        let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)

        var encryption: Encryption
        var sendData: NSData
        let orderedString = EnzevalosEncryptionHandler.sortMailaddressesByEncryption(allRec)
        var sendOperation: MCOSMTPSendOperation

        //TODO: Consider pref enc = false
        
        if let encPGP = ordered[EncryptionType.PGP] {
            encryption = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)!
            if let encData = encryption.signAndEncrypt("\n"+message, mailaddresses: orderedString[EncryptionType.PGP]!) { //ohne "\n" wird der erste Teil der Nachricht, bis sich ein einzelnen \n in einer Zeile befindet nicht in die Nachricht getan
                //sendData = encData
                builder.textBody = String(data: encData, encoding: NSUTF8StringEncoding)
                sendData = builder.data()
                sendOperation = session.sendOperationWithData(sendData, from: userID, recipients: encPGP)
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
            sendOperation = session.sendOperationWithData(sendData, from: userID, recipients: unenc)
            //TODO handle different callbacks
            sendOperation.start(callback)
        }
    }

    func setupIMAPSession() {
        let imapsession = MCOIMAPSession()
        imapsession.hostname = UserManager.loadUserValue(Attribute.IMAPHostname) as! String
        imapsession.port = UInt32(UserManager.loadUserValue(Attribute.IMAPPort) as! Int)
        imapsession.username = UserManager.loadUserValue(Attribute.UserAddr) as! String
        imapsession.password = UserManager.loadUserValue(Attribute.UserPW) as! String
        imapsession.authType = MCOAuthType.SASLPlain
        imapsession.connectionType = MCOConnectionType.TLS
        self.IMAPSes = imapsession
    }
    
    private func createSMTPSession()-> MCOSMTPSession{
        let session = MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.SMTPHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.SMTPPort) as! Int)
        session.username = (UserManager.loadUserValue(Attribute.UserAddr) as! String)
        session.password = UserManager.loadUserValue(Attribute.UserPW) as! String
        session.authType = MCOAuthType.SASLPlain
        session.connectionType = MCOConnectionType.StartTLS
        return session
    }



    func addFlag(uid: UInt64, flags: MCOMessageFlag, folder: String = "INBOX") {
        let op = self.IMAPSession.storeFlagsOperationWithFolder(folder, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.Set, flags: flags)
        op.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            }
        }
    }

    func removeFlag(uid: UInt64, flags: MCOMessageFlag, folder: String = "INBOX") {
        let op = self.IMAPSession.storeFlagsOperationWithFolder(folder, uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.Remove, flags: flags)

        op.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            } else {
                print("Succsessfully updated flags!")
            }
        }
    }


    func receiveAll(folder: String = "INBOX", newMailCallback: (() -> ()), completionCallback: ((error: Bool) -> ())) {
        let uids: MCOIndexSet
        uids = MCOIndexSet(range: MCORangeMake(DataHandler.handler.maxUID, UINT64_MAX))
        loadMessagesFromServer(uids, record: nil, newMailCallback: newMailCallback, completionCallback: completionCallback)
    }

    func loadMoreMails(record: KeyRecord, folder: String = "INBOX", newMailCallback: (() -> ()), completionCallback: ((error: Bool) -> ())) {
        let addresses: [MailAddress]
        addresses = record.addresses

        for adr in addresses {
            let searchExpr: MCOIMAPSearchExpression = MCOIMAPSearchExpression.searchFrom(adr.mailAddress)
            let searchOperation: MCOIMAPSearchOperation = self.IMAPSession.searchExpressionOperationWithFolder(folder, expression: searchExpr)

            searchOperation.start { (err, indices) -> Void in
                guard err == nil else {
                    completionCallback(error: true)
                    return
                }
                let ids = indices as MCOIndexSet?
                if var setOfIndices = ids {
                    for mail in record.mails {
                        setOfIndices.removeIndex(mail.uid)
                    }
                    if setOfIndices.count() == 0 {
                        completionCallback(error: false)
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

    func loadMessagesFromServer(uids: MCOIndexSet, folder: String = "INBOX", record: KeyRecord?, newMailCallback: (() -> ()), completionCallback: ((error: Bool) -> ())) {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue | MCOIMAPMessagesRequestKind.Flags.rawValue)
        let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = [AUTOCRYPTHEADER]
        
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(err)")
                completionCallback(error: true)
                return
            }
            if let msgs = msg {
                let dispatchGroup = dispatch_group_create()
                for m in msgs {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    dispatch_group_enter(dispatchGroup)

                    let op = self.IMAPSession.fetchParsedMessageOperationWithFolder(folder, uid: message.uid)
                    op.start { err, data in self.parseMail(err, parser: data, message: message, record: record, newMailCallback: newMailCallback)
                        dispatch_group_leave(dispatchGroup)
                    }
                }
                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
                    self.IMAPSession.disconnectOperation().start({ _ in })
                    completionCallback(error: false)
                }
            }
        }
    }
func parseMail(error: ErrorType?, parser: MCOMessageParser?, message: MCOIMAPMessage, record: KeyRecord?, newMailCallback: (() -> ())) {
      guard error == nil else {
            print("Error while fetching mail: \(error)")
            return
        }
        if let data = parser?.data() {
            let msgParser = MCOMessageParser(data: data)

            let html: String = msgParser.plainTextRendering()
            var lineArray = html.componentsSeparatedByString("\n")
           
            lineArray.removeFirst(4)
            var body = lineArray.joinWithSeparator("\n")
            body = body.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            body.appendContentsOf("\n")
            var rec: [MCOAddress] = []
            var cc: [MCOAddress] = []

            let header = message.header
            var autocrypt: AutocryptContact? = nil
            if let _ = header.extraHeaderValueForName(AUTOCRYPTHEADER){
                autocrypt = AutocryptContact(header: header)
                print(autocrypt?.toString())
                if(autocrypt?.type == EncryptionType.PGP && autocrypt?.key.characters.count > 0){
                    let pgp = ObjectivePGP.init()
                    pgp.importPublicKeyFromHeader((autocrypt?.key)!, allowDuplicates: false)
                    let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                    do {
                        let pgpKey = try pgp.keys[0].export()
                        enc?.addKey(pgpKey, forMailAddresses: [header.from.mailbox])
                    }
                    catch {
                        print("Could not conntect key! \(autocrypt?.toString())")
                    }
                }
                
            }
            if let to = header.to {
                for r in to {
                    rec.append(r as! MCOAddress)
                }
            }
            if let c = header.cc {
                for r in c {
                    cc.append(r as! MCOAddress)
                }
            }

            DataHandler.handler.createMail(UInt64(message.uid), sender: header.from, receivers: rec, cc: cc, time: header.date, received: true, subject: header.subject ?? "", body: body, flags: message.flags, record: record, autocrypt: autocrypt) //@Olli: fatal error: unexpectedly found nil while unwrapping an Optional value //crash wenn kein header vorhanden ist
            newMailCallback()
        }
    }


    private func cutIndexSet(inputSet: MCOIndexSet, maxMails: Int = MAXMAILS) -> MCOIndexSet {
        let max = UInt32(maxMails)
        if inputSet.count() <= max {
            return inputSet
        }
        let result = MCOIndexSet()
        for x in inputSet.nsIndexSet().reverse() {
            if(result.count() < max) {
                result.addIndex(UInt64(x))
            }
        }
        return result
    }


    func findMaxUID(folder: String = "INBOX", callback: ((maxUID: UInt64) -> ())) {
        //TODO: NSP!!!
        var maxUID: UInt64 = 0
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(0, UINT64_MAX))
        let dispatchGroup = dispatch_group_create()
        dispatch_group_enter(dispatchGroup)

        let fetchOperation: MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
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
            dispatch_group_leave(dispatchGroup)
        }
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
            callback(maxUID: maxUID)
        }
    }

    /*
     Parameters:
     ---------------
     
     Folder = ["INBOX"] (Default)
     #mails = 200 (Default)
     Look forspefic mail addreses (of Contacts) (optional) -> more folders?
     Look for spefic threadID (optional) -> more folders?
     Look for spefic date (optional) -> more folders
     Look for unread messages (optional)
     /
    func lookForMailAddresses(mailaddresses: [String]?, startDate: NSDate?, endDate: NSDate?, folders: [String] = ["INBOX"], maxMails: Int = MAXMAILS, callback: ((mails: [Mail]) -> ()) ){
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            
        let dispatchGroup = dispatch_group_create()

        if let mailadr = mailaddresses{
            for adr in mailadr{
                dispatch_group_enter(dispatchGroup)
                self.lookForMailAddress(adr, startDate: startDate, endDate: endDate, folders: folders, dispatchGroup: dispatchGroup, callback: callback)
            }
        }
        else{
            dispatch_group_enter(dispatchGroup)
            self.lookForDate(startDate: startDate, endDate: endDate, folders: folders, dispatchGroup: dispatchGroup, callback: callback)
        }
    }
    
    private func lookForDate(expr: MCOIMAPSearchExpression? = nil, startDate: NSDate?, endDate: NSDate?, folders: [String], dispatchGroup: dispatch_group_t,  callback: ((mails: [Mail]) -> ())){
        if expr == nil && startDate == nil && endDate == nil{
            //return nil
        }
        var ids: MCOIndexSet?
        var searchExpr: MCOIMAPSearchExpression
        
        if expr != nil{
            searchExpr = expr!
        }
        else {
            searchExpr = MCOIMAPSearchExpression()
        }
        if startDate != nil {
            let exprStartDate: MCOIMAPSearchExpression = MCOIMAPSearchExpression.searchSinceReceivedDate(startDate)
            searchExpr = MCOIMAPSearchExpression.searchAnd(searchExpr, other: exprStartDate)
        }
        if endDate != nil {
            let exprEndDate: MCOIMAPSearchExpression = MCOIMAPSearchExpression.searchBeforeDate(endDate)
            searchExpr = MCOIMAPSearchExpression.searchAnd(searchExpr, other: exprEndDate)
        }
        let searchOperation: MCOIMAPSearchOperation = self.IMAPSession.searchExpressionOperationWithFolder(folders[0], expression: searchExpr)

        searchOperation.start { (err, indices) -> Void  in
            guard err == nil else {
                return
            }
            ids = indices as MCOIndexSet?
            //TODO Make thread safe!!!

<<<<<<< HEAD
            // Handle mails!
            dispatch_group_leave(dispatchGroup)
 
        }
        
=======
    func loadMoreMails(record: KeyRecord, newMailCallback: (() -> ()), completionCallback: ((error: Bool) -> ())) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            completionCallback(error: false)
        })
>>>>>>> 3b095ad801e84b3f530f67c054a4adb8cdb465d7
    }
    
    
    private func lookForMailAddress(mailaddress: String, startDate: NSDate?, endDate: NSDate?, folders: [String], dispatchGroup: dispatch_group_t,  callback: ((mails: [Mail]) -> ())){
        print(mailaddress)
        let searchExpr: MCOIMAPSearchExpression = MCOIMAPSearchExpression.searchFrom(mailaddress)
        lookForDate(searchExpr, startDate: startDate, endDate: endDate, folders: folders, dispatchGroup: dispatchGroup,  callback: callback)
       
    }
 */

}
