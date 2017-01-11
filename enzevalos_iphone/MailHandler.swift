//
//  MailHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 22.08.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

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
    var lastUID: UInt64 = DataHandler.getDataHandler().readMaxUid()
    
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
        
        var enc : [MCOAddress] = []
        var unenc : [MCOAddress] = []
        let handler = KeyHandler.getHandler()
        let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)
        var keys : [PGPKey] = []
        
        for rec in allRec{
            if handler.addrHasKey(rec) {
                enc.append(MCOAddress(displayName: "", mailbox: rec))
                //let sendOperation = session.sendOperationWithData(builder.openPGPEncryptedMessageDataWithEncryptedData(CryptoHandler.getHandler().pgp.encryptData(message.dataUsingEncoding(NSUTF8StringEncoding)!, usingPublicKeys: )), from: userID, recipients: ["jakob.bode@fu-berlin.de"])//session.sendOperationWithData(rfc822Data)
                //sendOperation.start(callback)
                if let key = KeyHandler.getHandler().getKeyByAddr(rec) {
                    if !keys.contains(key.key) {
                        keys.append(key.key)
                    }
                }
                //TODO: error in callback senden
                else {
                    print("ERROR NO KEY!!! MailHandler line 102")
                    //unenc.append(MCOAddress(displayName: "", mailbox: rec))
                }
            }
            else {
                unenc.append(MCOAddress(displayName: "", mailbox: rec))
                print(unenc)
            }
        }
        //TODO: handle different cases
        do {
            var sendOperation = session.sendOperationWithData(builder.openPGPEncryptedMessageDataWithEncryptedData(try CryptoHandler.getHandler().pgp.encryptData(("\n"+message).dataUsingEncoding(NSUTF8StringEncoding)!, usingPublicKeys: keys, signWithSecretKey: KeyHandler.getHandler().getPrivateKey()?.key, passphrase: nil, armored: true)), from: userID, recipients: enc) //ohne "\n" wird der erste Teil der Nachricht, bis sich ein einzelnen \n in einer Zeile befindet nicht in die Nachricht getan
            //print("message to be encrypted:")
            //print(String(data: message.dataUsingEncoding(NSUTF8StringEncoding)!, encoding: NSUTF8StringEncoding))
        
            if enc != [] {
                sendOperation.start(callback)
            }
            if unenc != [] {
                let rfc822Data = builder.data()
                sendOperation = session.sendOperationWithData(rfc822Data, from: userID, recipients: unenc)
                sendOperation.start(callback)
            }
        }
        catch _ {
            print("Error while sending; MailHandler, line 125")
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
    
    func recieve() {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue | MCOIMAPMessagesRequestKind.Flags.rawValue)
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(lastUID, UINT64_MAX))
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
                        
                        var enc = false
                        let ver = false
                        let troub = false
                        let decBody : String? = nil
                        
                        //gute Wahl?
                        //in-line PGP
                        if body.commonPrefixWithString("-----BEGIN PGP MESSAGE-----", options: NSStringCompareOptions.CaseInsensitiveSearch) == "-----BEGIN PGP MESSAGE-----" {
                            enc = true
                        }
                        //TODO: Fix UID -> UInt64, Int64, UInt 32...??????
                        // TODO: Fix decryption
                        
                        let mail = DataHandler.getDataHandler().createMail(UInt64(message.uid), sender: header.from, receivers: rec, cc: cc, time: header.date, received: true, subject: header.subject, body: body, decryptedBody: decBody, isEncrypted: enc, isVerified: ver, trouble: troub, flags: message.flags)
                      //  mail.decryptIfPossible()
                        /*Jakob prototypeänderung Ende*/
                        self.delegate?.addNewMail(mail)
                        
                        dispatch_group_leave(dispatchGroup)
                    }
                    self.lastUID = biggest
                }
                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
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
            } else {
                print("Succsessfully updated flags!")
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
}
