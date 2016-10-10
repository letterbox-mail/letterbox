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
    
    var IMAPSession: MCOIMAPSession?
    
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
        
        builder.htmlBody = message
        
        let rfc822Data = builder.data()
        let sendOperation = session.sendOperationWithData(rfc822Data)
        
        sendOperation.start(callback)
    }
    
    func setupIMAPSession() {
        let imapsession = MCOIMAPSession()
        imapsession.hostname = IMAPHostname
        imapsession.port = IMAPPort
        imapsession.username = useraddr
        imapsession.password = pw
        imapsession.authType = MCOAuthType.SASLPlain
        imapsession.connectionType = MCOConnectionType.TLS
        self.IMAPSession = imapsession
    }
    
    func recieve() {
        if IMAPSession == nil {
            setupIMAPSession()
        }
        
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue | MCOIMAPMessagesRequestKind.Flags.rawValue)
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(lastUID, UINT64_MAX))
        let fetchOperation : MCOIMAPFetchMessagesOperation = self.IMAPSession!.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            if let error = err {
                print("error from server \(error)")
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
                    let op = self.IMAPSession!.fetchMessageByUIDOperationWithFolder(folder, uid: message.uid)
                    op.start { (err, data) -> Void in
                        let msgParser = MCOMessageParser(data: data)
                        let html: String = msgParser.plainTextBodyRendering()
                        var rec: [MCOAddress] = []
                        let header = message.header
                        let messageRead = message.flags.rawValue & MCOMessageFlag.Seen.rawValue == MCOMessageFlag.Seen.rawValue
                        if let cc = header.cc {
                            for r in cc {
                                rec.append(r as! MCOAddress)
                            }
                        }
                        let mail = Mail(uid: message.uid, sender: header.from, receivers: rec, time: header.date, received: true, subject: header.subject, body: html, isEncrypted: false, isVerified: false, trouble: false, isUnread: !messageRead, flags: message.flags)
                        
                        self.delegate?.addNewMail(mail)
                        
                        dispatch_group_leave(dispatchGroup)
                    }
                    self.lastUID = biggest
                }
                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
                    self.delegate?.getMailCompleted()
                    self.IMAPSession?.disconnectOperation().start({_ in })
                }
            }
        }
    }
    
    func addFlag(uid: UInt64, flags: MCOMessageFlag) {
        if IMAPSession == nil {
            setupIMAPSession()
        }
        let op = self.IMAPSession!.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: flags)
        
        op.start { error -> Void in
            if let err = error {
                print("Error: \(err)")
            } else {
                print("Succsessfully updated flags!")
            }
        }
    }
    
    func removeFlag(uid: UInt64, flags: MCOMessageFlag) {
        if IMAPSession == nil {
            setupIMAPSession()
        }
        let op = self.IMAPSession!.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet.init(index: uid), kind: MCOIMAPStoreFlagsRequestKind.Remove, flags: flags)
        
        op.start { error -> Void in
            if let err = error {
                print("Error: \(err)")
            } else {
                print("Succsessfully updated flags!")
            }
        }
    }
}
