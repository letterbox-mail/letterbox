//
//  Logger.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 25.10.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

class Logger {
    
    /**
     * Attention: assumes message to be right escaped (espacially ',')
     */
    static func log(message: String, type: Log) {

        /*
         Date,type,...
         */

        var entries: [String] = []
        let now = Date()
        entries.append(escape(message: now.description))
        entries.append(escape(message: type.rawValue))
        entries.append(message)
        NSLog("\(entries.joined(separator: ","))")
    }

    /**
     * Attention: assumes message to be right escaped (espacially ',')
     */
<<<<<<< HEAD
    static func logMail(with from: String, to: [String], cc: [String], bcc: [String], bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, /*decryptedWithOldPrivateKey = false,*/ isSigned: Bool, /*isCorrectlySigned = true,*/ keyID: String, message: String) {
        
        /*
         Date,type,from,cc,bcc,bodyLength,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey,isSigned,isCorrectlySigned,keyID,...
         */
        
        var messages: [String] = []
        messages.append(escape(message: resolve(mailAddress: from)))
        
        //to
        var array: [String] = []
        for entry in to {
            array.append(resolve(mailAddress: entry))
        }
        messages.append(escape(message: array.joined(separator: ";")))
        
        //cc
        array = []
        for entry in cc {
            array.append(resolve(mailAddress: entry))
        }
        messages.append(escape(message: array.joined(separator: ";")))
        
        //bcc
        array = []
        for entry in bcc {
            array.append(resolve(mailAddress: entry))
        }
        messages.append(escape(message: array.joined(separator: ";")))
        
        //bodyLength
        messages.append(escape(message: String(bodyLength)))
        
        //isEncrypted
        messages.append(escape(message: String(isEncrypted)))
        
        //decryptedBodyLength
        messages.append(escape(message: String(decryptedBodyLength)))
        
        //decryptedWithOldPrivateKey
        messages.append(escape(message: String(false)))
        
        //isSigned
        messages.append(escape(message: String(isSigned)))
        
        //isCorrectlySigned
        messages.append(escape(message: String(true)))
        
        //keyID - the keyID the message was signed with
        messages.append(escape(message: resolve(keyID: keyID)))
        
        //message
        messages.append(message)
        
        log(message: messages.joined(separator: ","), type: Log.mail)
    }
    
    static func log(sent from: String, to: [String], cc: [String], bcc: [String], bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, /*decryptedWithOldPrivateKey = false,*/ isSigned: Bool, /*isCorrectlySigned = true,*/ keyID: String, /*, sent*/ secureAddresses: [String], otherKeyIDs: [String]) {
        /*
         Date,type,from,cc,bcc,bodyLength,inSentFolder,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey(=false),isSigned,isCorrectlySigned(=true),keyID,sent,secureAddresses,otherKeyIDs
         */
        var messages: [String] = []
        //sent - mailLog-type
        messages.append(escape(message: MailLog.sent.rawValue))
        
        //secureAddresses
        var array: [String] = []
        for entry in secureAddresses {
            array.append(resolve(mailAddress: entry))
        }
        messages.append(escape(message: array.joined(separator: ";")))
        
        //otherKeyIDs
        array = []
        for entry in otherKeyIDs {
            array.append(resolve(keyID: entry))
        }
        messages.append(escape(message: array.joined(separator: ";")))
        
        logMail(with: from, to: to, cc: cc, bcc: bcc, bodyLength: bodyLength, isEncrypted: isEncrypted, decryptedBodyLength: decryptedBodyLength, isSigned: isSigned, keyID: keyID, message: messages.joined(separator: ","))
    }
    
    /**
     * Attention: assumes message to be right escaped (espacially ',')
     */
    static func log(generic mail: PersistentMail, message: String) {

        /*
         Date,type,from,cc,bcc,bodyLength,inSentFolder,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey,isSigned,isCorrectlySigned,keyID...
         */
        //maybe add a resolved subject?
        
        var messages: [String] = []
        messages.append(escape(message: resolve(mailAddress: mail.from)))
        var to: [String] = []
        for addr in mail.to {
            to.append(resolve(mailAddress: addr as! MailAddress))
        }
        messages.append(escape(message: to.joined(separator: ";")))

        var cc: [String] = []
        if let mailCC = mail.cc {
            for addr in mailCC {
                cc.append(resolve(mailAddress: addr as! MailAddress))
            }
        }
        messages.append(escape(message: cc.joined(separator: ";")))

        var bcc: [String] = []
        if let mailBCC = mail.bcc {
            for addr in mailBCC {
                bcc.append(resolve(mailAddress: addr as! MailAddress))
            }
        }
        messages.append(escape(message: bcc.joined(separator: ";")))

        messages.append(escape(message: String((mail.body ?? "").count)))
        
        messages.append(escape(message: String(mail.folder.path == UserManager.backendSentFolderPath)))
        
        messages.append(escape(message: String(mail.isEncrypted)))
        messages.append(escape(message: String(mail.unableToDecrypt)))
        messages.append(escape(message: String((mail.decryptedBody ?? "").count)))
        messages.append(escape(message: String(mail.decryptedWithOldPrivateKey)))
        
        messages.append(escape(message: String(mail.isSigned)))
        messages.append(escape(message: String(mail.isCorrectlySigned)))
        messages.append(escape(message: resolve(keyID: mail.keyID ?? "")))
        
        messages.append(message)
        log(message: "\(messages.joined(separator: ","))", type: .mail)
    }

    static func log(received mail: PersistentMail) {
        /*
         Date,type,from,cc,bcc,bodyLength,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey,isSigned,isCorrectlySigned,keyID,received,,
         */
        log(generic: mail, message: escape(message: MailLog.received.rawValue)+",,")
    }

    static func log(read mail: PersistentMail) {
        /*
         Date,type,from,cc,bcc,bodyLength,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey,isSigned,isCorrectlySigned,keyID,read,,
         */
        log(generic: mail, message: escape(message: MailLog.read.rawValue)+",,")
    }
    
    /*static func log(sent mail: PersistentMail) {
        /*
         Date,type,from,cc,bcc,bodyLength,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey,isSigned,isCorrectlySigned,keyID,sent
         */
        MailLog.sent.append(mail: mail)
    }*/
    

    static func log(sent mail: PersistentMail) {

    }

    static func logInbox() {
        let inbox = DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath)
        let nrOfMails = inbox.mailsOfFolder.count
        let nrOfSecureMails = inbox.mailsOfFolder.reduce(0, { $1.isSecure ? $0 + 1: $0 })
        let nrOfTroubleMails = inbox.mailsOfFolder.reduce(0, { $1.trouble ? $0 + 1: $0 })
        
        // temporary: move this to appropriate functions later
        let nrOfFolders = DataHandler.handler.allFolders.count
        let gesendet = DataHandler.handler.findFolder(with: UserManager.backendSentFolderPath)
        let nrOfGesendetMails = gesendet.mailsOfFolder.count
        
    }

    //get an pseudonym for a mailAddress
    static func resolve(mailAddress: MailAddress) -> String {
        return resolve(mailAddress: mailAddress.mailAddress)
    }
    
    //get an pseudonym for a mailAddress
    static func resolve(mailAddress: String) -> String {
        return DataHandler.handler.getPseudonymMailAddress(mailAddress: mailAddress).pseudonym
    }
    
    //get an pseudonym for a keyID
    static func resolve(keyID: String) -> String {
        return ""
    }
    
    //escape the entry of one cell in a csv
    static func escape(message: String) -> String {
        var mess = message
        if mess.contains(",") || mess.contains("\"") {
            mess = "\"" + mess.components(separatedBy: "") .map { $0 == "\"" ? "\"\"": $0 }.joined() + "\""
        }
        return mess
    }
}

enum Log: String {
    case
    unknown = "unknown", //unknown type
    key = "key", //If a new key is discovered/created/verified/etc. this should be logged here
    mail = "mail", //If a new mail is received or send, this should be logged here
    ui = "ui", //If a specific UI-element (e.g warning, error message, info button) is triggered, the event should be logged here
    bug = "bug" //Bugs produced by us should log in this type

    /*func append(message: String) {
        Logger.log(message: Logger.escape(message: message), type: self)
    }*/
}

enum MailLog: String {
    case
    unknown = "unknown", //unknown type
    read = "read", //mail was read by participant
    sent = "sent", //mail is sent by participant
    received = "receive" //mail is received by participant
    
    func append(mail: PersistentMail) {
        /*
         Date,type,from,cc,bcc,bodyLength,isEncrypted,unableToDecrypt,decryptBodyLength,decryptedWithOldPrivateKey,isSigned,isCorrectlySigned,keyID,mailLog
         */
        Logger.log(generic: mail, message: Logger.escape(message: self.rawValue))
    }
}
