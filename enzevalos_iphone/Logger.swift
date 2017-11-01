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
    static func log(generic mail: PersistentMail, message: String) {

        /*
         Date,type,from,cc,bcc,bodyLength...
         */

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

        messages.append(message)
        log(message: "\(messages.joined(separator: ","))", type: .mail)
    }

    static func log(received mail: PersistentMail) {

    }

    static func log(read mail: PersistentMail) {

    }

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

    static func resolve(mailAddress: MailAddress) -> String {
        return ""
    }

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

