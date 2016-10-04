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
    
    var delegate: InboxCellDelegator?
    
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
    
    func recieve() {
        let imapsession = MCOIMAPSession()
        imapsession.hostname = IMAPHostname
        imapsession.port = IMAPPort
        imapsession.username = useraddr
        imapsession.password = pw
        imapsession.authType = MCOAuthType.SASLPlain
        imapsession.connectionType = MCOConnectionType.TLS
        
        let requestKind = MCOIMAPMessagesRequestKind(rawValue: MCOIMAPMessagesRequestKind.Headers.rawValue | MCOIMAPMessagesRequestKind.Flags.rawValue)
        let folder = "INBOX"
        let uids = MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        let fetchOperation : MCOIMAPFetchMessagesOperation = imapsession.fetchMessagesOperationWithFolder(folder, requestKind: requestKind, uids: uids)
        fetchOperation.start { (err, msg, vanished) -> Void in
            if let error = err {
                print("error from server \(error)")
            }
            if let msgs = msg {
                for m in msgs {
                    let message: MCOIMAPMessage = m as! MCOIMAPMessage
                    let op = imapsession.fetchMessageByUIDOperationWithFolder(folder, uid: message.uid)
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
                        let mail = Mail(uid: message.uid, sender: header.from, receivers: rec, time: header.date, received: true, subject: header.subject, body: html, isEncrypted: false, isVerified: false, trouble: false, isUnread: !messageRead)
                        
                        print("Got new Mail!")
                        self.delegate?.addNewMail(mail)
                        
                    }
                }
            }
        }
        
        //        imapsession.disconnectOperation().start {
        //            (error) -> Void in
        //            if let e = error {
        //                print("Error while disconnecting: \(e)")
        //            }
        //
        //        }
        //        return returns
    }
    
}
