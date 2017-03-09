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


let EXTRAHEADERS = ["Inbome","Autocrypt-ENCRYPTION"]
let TO = "to"
let TYPE = "type"
let ENCRYPTION = "prefer-encrypted"
let KEY = "key"


class AutocryptContact{
    enum AutocryptType: Int{
        case OPENPGP, ERROR
        var string:String{
            switch self{
            case .OPENPGP:
                return "p"
            default:
                return "error"
            }
        }
        static func getType(type:String) ->AutocryptType{
            switch type{
                case "p":
                    return AutocryptType.OPENPGP
                case "":
                    return AutocryptType.OPENPGP
            default:
                return ERROR
            }
        }
    }
    
    var addr: String = ""
    var type: AutocryptType = .OPENPGP
    var prefer_encryption: Bool = false
    var key: String = ""
    
    init(addr: String, type: String, prefer_encryption: String, key: String){
        self.addr = addr
        self.type = AutocryptType.getType(type)
        setPrefer_encryption(prefer_encryption)
        self.key = key
    }
    
    
    convenience init(header: MCOMessageHeader){
        let autocrypt = header.extraHeaderValueForName(EXTRAHEADERS[0])
        var field: [String]
        var addr = ""
        var type = ""
        var pref = ""
        var key = ""
        
        if(autocrypt != nil){
            let autocrypt_fields = autocrypt.componentsSeparatedByString(";")
            for f in autocrypt_fields{
                field = f.componentsSeparatedByString("=")
                if field.count > 1{
                    let flag = field[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                    var value = field[1]
                    if field.count > 2 {
                        for i in 2...(field.count - 1){
                            value = value + field[i]
                        }
                    }
                    switch flag{
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
                        key = value
                        break
                    default:
                        break
                    }
                }
            }
        }
        self.init(addr: addr, type: type, prefer_encryption: pref, key: key)
    }
    
    func validateContact()->Bool{
        if addr != "" && type != .ERROR && key != ""{
            return true
        }
        return false
    }
    
    func setPrefer_encryption(input:String)->Bool{
        if input == "yes" || input == "YES" || input == "Yes"{
            prefer_encryption = true
            return true
        }
        else if input == "no" || input == "NO" || input == "No"{
            prefer_encryption = false
            return true
        }
        return false
    }
    
    func toString()->String{
        return "Addr: \(addr) | type: \(type) | encryption? \(prefer_encryption) | key: \(key)"
    }
}

class MailHandler {

    var delegate: MailHandlerDelegator?
    
    private static let MAXMAILS: Int = 30
    
    
    
    private let concurrentMailServer = dispatch_queue_create(
        "com.enzevalos.mailserverQueue", DISPATCH_QUEUE_CONCURRENT)
    
    var lastUID: UInt64 = DataHandler.handler.maxUID
    
    
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
    
    
    func add_autocrypt_header(builder: MCOMessageBuilder){
        // Autocrypt-ENCRYPTION: to=aaa@bbb.cc; [type=(p|...);] [prefer-encrypted=(yes|no);] key=BASE64 
        let autocrypt = "to="+(UserManager.loadUserValue(Attribute.UserAddr) as! String)+"; type="+(UserManager.loadUserValue(Attribute.AutocryptType) as! String)+"; prefer-encrypted="+(UserManager.loadUserValue(Attribute.PrefEncryption) as! String)+"; key="+(UserManager.loadUserValue(Attribute.PublicKey) as! String)
        
        builder.header.setExtraHeaderValue(autocrypt, forName: "Autocrypt-ENCRYPTION")
    }
    
    //return if send successfully
    func send(toEntrys : [String], ccEntrys : [String], bccEntrys : [String], subject : String, message : String, callback : (NSError?) -> Void){
        //http://stackoverflow.com/questions/31485359/sending-mailcore2-plain-emails-in-swift
        
        let useraddr = (UserManager.loadUserValue(Attribute.UserAddr) as! String)
        let username = UserManager.loadUserValue(Attribute.UserName) as! String
        
        let session =  MCOSMTPSession()
        session.hostname = UserManager.loadUserValue(Attribute.SMTPHostname) as! String
        session.port = UInt32(UserManager.loadUserValue(Attribute.SMTPPort) as! Int)
        session.username = useraddr
        session.password = UserManager.loadUserValue(Attribute.UserPW) as! String
        session.authType = MCOAuthType.SASLPlain
        session.connectionType = MCOConnectionType.StartTLS
        
        let builder = MCOMessageBuilder()
        
        var toReady : [MCOAddress] = []
        for addr in toEntrys {
            toReady.append(MCOAddress(displayName: addr, mailbox: addr))
        }
        builder.header.to = toReady
        
        var ccReady : [MCOAddress] = []
        for addr in ccEntrys {
            ccReady.append(MCOAddress(displayName: addr, mailbox: addr))
        }
        builder.header.cc = ccReady
        
        var bccReady : [MCOAddress] = []
        for addr in bccEntrys {
            bccReady.append(MCOAddress(displayName: addr, mailbox: addr))
        }
        builder.header.bcc = bccReady
        
        builder.header.from = MCOAddress(displayName: username , mailbox: useraddr)
        
        builder.header.subject = subject
        
        add_autocrypt_header(builder)
        
        builder.textBody = message //htmlBody = message
        
        //let rfc822Data = builder.data()
        
        var allRec : [String] = []
        allRec.appendContentsOf(toEntrys)
        allRec.appendContentsOf(ccEntrys)
        
        //TODO add support for different Encryptions here
        //edit sortMailaddressesByEncryptionMCOAddress and sortMailaddressesByEncryption because a mailaddress can be found in multiple Encryptions
        let ordered = EnzevalosEncryptionHandler.sortMailaddressesByEncryptionMCOAddress(allRec)
        
        let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)
        
        var encryption : Encryption
        var sendData : NSData
        let orderedString = EnzevalosEncryptionHandler.sortMailaddressesByEncryption(allRec)
        var sendOperation: MCOSMTPSendOperation
            
        if let encPGP = ordered[EncryptionType.PGP] {
            encryption = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)!
            //TODO use encryptAndSign instead of encrypt
            if let encData = encryption.encrypt("\n"+message, mailaddresses: orderedString[EncryptionType.PGP]!) { //ohne "\n" wird der erste Teil der Nachricht, bis sich ein einzelnen \n in einer Zeile befindet nicht in die Nachricht getan
                sendData = encData
                sendOperation = session.sendOperationWithData(builder.openPGPEncryptedMessageDataWithEncryptedData(sendData), from: userID, recipients: encPGP)
                //TODO handle different callbacks
                sendOperation.start(callback)
            }
            else {
                //TODO do it better
                callback(NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError, userInfo: nil))
            }
        }
        
        //TODO add new encryptions here
            
        if let unenc = ordered[EncryptionType.unknown] {
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
    
    private func cutIndexSet(inputSet: MCOIndexSet, maxMails: Int = MAXMAILS)->MCOIndexSet{
        let max = UInt32(maxMails)
        if inputSet.count() <= max{
            return inputSet
        }
        let result = MCOIndexSet()
        for x in inputSet.nsIndexSet().reverse(){
            if(result.count() < max){
                result.addIndex(UInt64(x))
            }
        }
        return result
    }
    
    func receive(folders: [String] = ["INBOX"], ids: MCOIndexSet?, maxMails: Int = MAXMAILS){
        let uids: MCOIndexSet
        if ids == nil{
            uids = findUids()
            print("#UIDs:\(uids.count())")
        }
        else{
            uids = cutIndexSet(ids!)
        }
        
    
    }
    
   
    
    func recieve(folder: String = "INBOX") {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue | MCOIMAPMessagesRequestKind.Flags.rawValue)
        let uids: MCOIndexSet
        let ids: MCOIndexSet? = nil
        if ids != nil{
            uids = ids!
        }
        else{
            uids = MCOIndexSet(range: MCORangeMake(lastUID, UINT64_MAX))
        }
        let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
        fetchOperation.extraHeaders = EXTRAHEADERS
        
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(err)")
                return
            }
            if let msgs = msg {
                var biggest = self.lastUID
                let dispatchGroup = dispatch_group_create()
                for m in msgs {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    if UInt64(message.uid) > biggest {
                        biggest = UInt64(message.uid)
                    }
                    dispatch_group_enter(dispatchGroup)
                    let op = self.IMAPSession.fetchMessageByUIDOperationWithFolder(folder, uid: message.uid)
                    op.start { (err, data) -> Void in
                        guard err == nil else {
                            print("Error while fetching mail: \(err)")
                            return
                        }
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
                        
                        // TODO: Handle here autocrypt
                        
                        
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
                        
                        //gute Wahl?
                        //in-line PGP
                        if body.commonPrefixWithString("-----BEGIN PGP MESSAGE-----", options: NSStringCompareOptions.CaseInsensitiveSearch) == "-----BEGIN PGP MESSAGE-----" {
                        }
                        //TODO: Fix UID -> UInt64, Int64, UInt 32...??????
                        // TODO: Fix decryption
                        
                        let mail = DataHandler.handler.createMail(UInt64(message.uid), sender: header.from, receivers: rec, cc: cc, time: header.date, received: true, subject: header.subject ?? "", body: body, flags: message.flags)
                      //  mail.decryptIfPossible()
                        /*Jakob prototypeänderung Ende*/
                        self.delegate?.addNewMail(mail)
                        
                        dispatch_group_leave(dispatchGroup)
                    }
                    if ids == nil{
                        self.lastUID = biggest
                    }
                }
                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
                    print("Receive finish")
                    self.delegate?.getMailCompleted()
                    self.IMAPSession.disconnectOperation().start({_ in })
                }
            }
        }
    }
    
    func addFlag(uid: UInt64, flags: MCOMessageFlag) {
        let op = self.IMAPSession.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.Set, flags: flags)
        
        op.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            }
        }
    }
    
    func removeFlag(uid: UInt64, flags: MCOMessageFlag) {
        let op = self.IMAPSession.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.Remove, flags: flags)
        
        op.start { error -> Void in
            if let err = error {
                print("Error while updating flags: \(err)")
            } else {
                print("Succsessfully updated flags!")
            }
        }
    }
    
    func findUids(folder: String = "INBOX", maxIds: Int = MAXMAILS)->MCOIndexSet{
        let result = MCOIndexSet()
        let max = UInt64(maxIds)
        var maxID = findMaxUID(folder)
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue)
        var dif = max - UInt64(result.count())
        print("My last id: \(self.lastUID)")
        while dif > 0 {
            var minID: UInt64 = UInt64.subtractWithOverflow(maxID, dif)
            print("next ID: \(minID)")
            if self.lastUID > minID {
                minID = self.lastUID
            }
            
            let uids = MCOIndexSet(range: MCORangeMake(minID, maxID))
            let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
            fetchOperation.start { (err, msg, vanished) -> Void in
                guard err == nil else {
                    print("Error while fetching inbox: \(err)")
                    return
                }
                if let msgs = msg {
                    for m in msgs{
                        let message: MCOIMAPMessage = m as! MCOIMAPMessage
                        let id = UInt64(message.uid)
                        result.addIndex(id)
                    }
                }
            }
            maxID = minID
            if(maxID <= self.lastUID){
                break
            }
            dif = maxID - UInt64(result.count())
        }
        return result
    }
    
    func findMaxUID(folder: String = "INBOX")->UInt64{
        //TODO: NSP!!!
        var maxUID: UInt64 = 0
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue)
        let uids = MCOIndexSet(range: MCORangeMake(0, UINT64_MAX))
        let dispatchGroup = dispatch_group_create()
        dispatch_group_enter(dispatchGroup)

        let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            guard err == nil else {
                print("Error while fetching inbox: \(err)")
                return
            }
            if let msgs = msg {
                for m in msgs{
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    let id = UInt64(message.uid)
                    if id > maxUID{
                        maxUID = id
                    }
                }
            }
        }
        dispatch_group_leave(dispatchGroup)

        return maxUID
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
     */
    func lookForMailAddresses(mailaddresses: [String]?, startDate: NSDate?, endDate: NSDate?, folders: [String] = ["INBOX"], maxMails: Int = MAXMAILS){
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            
        let dispatchGroup = dispatch_group_create()
        var ids = MCOIndexSet()

        if let mailadr = mailaddresses{
            for adr in mailadr{
                dispatch_group_enter(dispatchGroup)
                self.lookForMailAddress(adr, startDate: startDate, endDate: endDate, folders: folders, dispatchGroup: dispatchGroup, idPool: ids)
            }
        }
        else{
            dispatch_group_enter(dispatchGroup)
            self.lookForDate(startDate: startDate, endDate: endDate, folders: folders, dispatchGroup: dispatchGroup, idPool: ids)
        }
        dispatch_group_notify(dispatchGroup, self.concurrentMailServer) {
            self.receive(folders, ids: ids)
            
        }
        //TODO: Collect requests
            self.receive(ids: nil)
        } )
        
        
    }
    
    private func lookForDate(expr: MCOIMAPSearchExpression? = nil, startDate: NSDate?, endDate: NSDate?, folders: [String], dispatchGroup: dispatch_group_t, idPool: MCOIndexSet){
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
            idPool.addIndexSet(ids)
            
            dispatch_group_leave(dispatchGroup)
 
        }
        
    }
    
    
    private func lookForMailAddress(mailaddress: String, startDate: NSDate?, endDate: NSDate?, folders: [String], dispatchGroup: dispatch_group_t, idPool: MCOIndexSet){
        print(mailaddress)
        let searchExpr: MCOIMAPSearchExpression = MCOIMAPSearchExpression.searchFrom(mailaddress)
        lookForDate(searchExpr, startDate: startDate, endDate: endDate, folders: folders, dispatchGroup: dispatchGroup, idPool: idPool)
       
    }
}
