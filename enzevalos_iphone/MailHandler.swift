//
//  MailHandler.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 22.08.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import Foundation

class MailHandler {
    var user = "Alice"
    var useraddr = "alice2005@web.de"
    var pw = "WJ$CE:EtUo3E$"
    
    var hostname = "smtp.web.de"
    var port : UInt32 = 587
    
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
    
}
