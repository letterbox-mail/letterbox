//
//  MailHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 22.08.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import Foundation
import Contacts

class MailHandler {
    var user = "Alice"
    var useraddr = "alice2005@web.de"
    var pw = "WJ$CE:EtUo3E$"
    
    var hostname = "smtp.web.de"
    var port : UInt32 = 587
    
    var IMAPHostname = "imap.web.de"
    var IMAPPort: UInt32 = 993
    
    var delegate: MailHandlerDelegator?
    var lastUID: UInt64 = 1
    
    var IMAPSes: MCOIMAPSession?
    
    var IMAPSession: MCOIMAPSession {
        get {
            if IMAPSes == nil {
                setupIMAPSession()
            }
            
            return IMAPSes!
        }
    }
    
    //Anpassen:
    //Einstellungen in UserDefaults ablegen
    static func getAddr() -> String{
        return "alice2005@web.de"
    }
    
    //TODO: signatur hinzufügen
    
    
    //return if send successfully
    func send(toEntrys : [String], ccEntrys : [String], bccEntrys : [String], subject : String, message : String, callback : (NSError?) -> Void){
        //http://stackoverflow.com/questions/31485359/sending-mailcore2-plain-emails-in-swift
        
        let session =  MCOSMTPSession()
        session.hostname = hostname
        session.port = port
        session.username = useraddr
        session.password = pw
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
        
        builder.header.from = MCOAddress(displayName: user, mailbox:
            useraddr)
        
        builder.header.subject = subject
        
        builder.textBody = message //htmlBody = message
        
        //let rfc822Data = builder.data()
        
        var allRec : [String] = []
        allRec.appendContentsOf(toEntrys)
        allRec.appendContentsOf(ccEntrys)
        
        var enc : [MCOAddress] = []
        var unenc : [MCOAddress] = []
        let handler = KeyHandler.createHandler()
        let userID = MCOAddress(displayName: useraddr, mailbox: useraddr)
        var keys : [PGPKey] = []
        
        for rec in allRec{
            if handler.addrHasKey(rec) {
                enc.append(MCOAddress(displayName: "", mailbox: rec))
                //let sendOperation = session.sendOperationWithData(builder.openPGPEncryptedMessageDataWithEncryptedData(CryptoHandler.getHandler().pgp.encryptData(message.dataUsingEncoding(NSUTF8StringEncoding)!, usingPublicKeys: )), from: userID, recipients: ["jakob.bode@fu-berlin.de"])//session.sendOperationWithData(rfc822Data)
                //sendOperation.start(callback)
                if let key = KeyHandler.createHandler().getKeyByAddr(rec) {
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
            var sendOperation = session.sendOperationWithData(builder.openPGPEncryptedMessageDataWithEncryptedData(try CryptoHandler.getHandler().pgp.encryptData(("\n"+message).dataUsingEncoding(NSUTF8StringEncoding)!, usingPublicKeys: keys, signWithSecretKey: KeyHandler.createHandler().getPrivateKey()?.key, passphrase: nil, armored: true)), from: userID, recipients: enc) //ohne "\n" wird der erste Teil der Nachricht, bis sich ein einzelnen \n in einer Zeile befindet nicht in die Nachricht getan
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
        imapsession.hostname = IMAPHostname
        imapsession.port = IMAPPort
        imapsession.username = useraddr
        imapsession.password = pw
        imapsession.authType = MCOAuthType.SASLPlain
        imapsession.connectionType = MCOConnectionType.TLS
        self.IMAPSes = imapsession
    }
    
    func recieve() {
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue | MCOIMAPMessagesRequestKind.Flags.rawValue)
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(lastUID, UINT64_MAX))
        let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
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
                        let messageRead = MCOMessageFlag.Seen.isSubsetOf(message.flags)
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
                        /*Jakob prototypeänderung anfang*/
                        /*ursprünglicher Code :
                         
                        let mail = Mail(uid: message.uid, sender: header.from, receivers: rec, cc: cc, time: header.date, received: true, subject: header.subject, body: body, isEncrypted: false, isVerified: false, trouble: false, isUnread: !messageRead, flags: message.flags)

                         */
                        
                        /*CryptoHandler.getHandler().pgp.keys.append((KeyHandler.createHandler().getPrivateKey()?.key)!)
                        
                        let content = try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                        print(content)
                        
                        var signed : ObjCBool = false
                        var valid : ObjCBool = false
                        var integrityProtected : ObjCBool = false
                        
                        print(try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: KeyHandler.createHandler().getKeyByAddr(header.from.mailbox)?.key, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))*/
                        
                        
                        var enc = false
                        var ver = false
                        var troub = false
                        var decBody : String? = nil
                        
                        //gute Wahl?
                        //in-line PGP
                        if body.commonPrefixWithString("-----BEGIN PGP MESSAGE-----", options: NSStringCompareOptions.CaseInsensitiveSearch) == "-----BEGIN PGP MESSAGE-----" {
                            enc = true
                        }
                        
                        /*if enc {
                            if !CryptoHandler.getHandler().pgp.keys.contains((KeyHandler.createHandler().getPrivateKey()?.key)!) {
                                CryptoHandler.getHandler().pgp.keys.append((KeyHandler.createHandler().getPrivateKey()?.key)!)
                            }
                            do {
                                var signed : ObjCBool = false
                                var valid : ObjCBool = false
                                var integrityProtected : ObjCBool = false
                                
                                //verifyWithPublicKey: KeyHandler.createHandler().getKeyByAddr(header.from.mailbox)?.key
                                if (try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected) as NSData?) != nil && ((try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))! as NSData?) != nil{
                                    
                                    decBody = String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))! as NSData, encoding: NSUTF8StringEncoding)
                                    //print(String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected), encoding: NSUTF8StringEncoding)))
                                }
                                //print(try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))
                                //let content = try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                                //print(content)
                            } catch _ {
                                
                                troub = true
                                print("error while decrypting")
                            }
                        }*/ //now done in the MailObject itself
                            
                        /*if header.subject != nil {
                            if header.subject == "Schlüssel" {
                                enc = true
                            }
                            if header.subject == "Re: Prüfung"{
                                enc = true
                                troub = true
                            }
                            if header.subject == "Test4" {
                                ver = true
                                enc = true
                            }
                            if header.subject == "Multiple"{
                                enc = true
                            }
                            if header.subject == "Noch ein Test"{
                                enc = true
                                ver = true
                            }
                            if header.subject == "jetzt du"{
                                enc = true
                            }
                        }*/
                        let mail = Mail(uid: message.uid, sender: header.from, receivers: rec, cc: cc, time: header.date, received: true, subject: header.subject, body: body, decryptedBody: decBody, isEncrypted: enc, isVerified: ver, trouble: troub, isUnread: !messageRead, flags: message.flags)
                        mail.decryptIfPossible()
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
