//
//  Logger.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 25.10.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

class Logger {
    
    static let fileName = "log.json"
    
    static func log(mailSent event: Event, from: String, to: [String], cc: [String], bcc: [String], bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, decryptedWithOldPrivateKey: Bool = false, isSigned: Bool, isCorrectlySigned: Bool = true, signingKeyID: String, myKeyID: String, secureAddresses: [String] = [], encryptedForKeyIDs: [String] = []) {
        
        event.append(key: "type", value: LoggingEventType.mailSent)
        event.append(key: "from", value: from)
        event.append(key: "to", value: Logger.resolve(mailAddresses: to))
        event.append(key: "cc", value: Logger.resolve(mailAddresses: cc))
        event.append(key: "bcc", value: Logger.resolve(mailAddresses: bcc))
        event.append(key: "bodyLength", value: bodyLength)
        event.append(key: "isEncrypted", value: isEncrypted)
        event.append(key: "decryptedBodyLength", value: decryptedBodyLength)
        event.append(key: "decryptedWithOldPrivateKey", value: decryptedWithOldPrivateKey)
        event.append(key: "isSigned", value: isSigned)
        event.append(key: "isCorrectlySigned", value: isCorrectlySigned)
        event.append(key: "signingKeyID", value: Logger.resolve(keyID: signingKeyID))
        event.append(key: "myKeyID", value: Logger.resolve(keyID: myKeyID))
        event.append(key: "secureAddresses", value: Logger.resolve(mailAddresses:secureAddresses)) //means the addresses, which received a secure mail
        event.append(key: "encryptedForKeyIDs", value: Logger.resolve(keyIDs: encryptedForKeyIDs))
        
    }
    
    static func log(mailRead event: Event, from: String, to: [String], cc: [String], bcc: [String], bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, decryptedWithOldPrivateKey: Bool = false, isSigned: Bool, isCorrectlySigned: Bool = true, signingKeyID: String, myKeyID: String, secureAddresses: [String] = [], encryptedForKeyIDs: [String] = []) {
        
        event.append(key: "type", value: LoggingEventType.mailRead)
        event.append(key: "from", value: from)
        event.append(key: "to", value: Logger.resolve(mailAddresses: to))
        event.append(key: "cc", value: Logger.resolve(mailAddresses: cc))
        event.append(key: "bcc", value: Logger.resolve(mailAddresses: bcc))
        event.append(key: "bodyLength", value: bodyLength)
        event.append(key: "isEncrypted", value: isEncrypted)
        event.append(key: "decryptedBodyLength", value: decryptedBodyLength)
        event.append(key: "decryptedWithOldPrivateKey", value: decryptedWithOldPrivateKey)
        event.append(key: "isSigned", value: isSigned)
        event.append(key: "isCorrectlySigned", value: isCorrectlySigned)
        event.append(key: "signingKeyID", value: Logger.resolve(keyID: signingKeyID))
        event.append(key: "myKeyID", value: Logger.resolve(keyID: myKeyID))
        event.append(key: "secureAddresses", value: secureAddresses) //could mean the addresses, in this mail we have a key for
        event.append(key: "encryptedForKeyIDs", value: Logger.resolve(keyIDs: encryptedForKeyIDs))
        
    }
    
    static func log(mailRead event: Event, mail: PersistentMail) {
        
        event.append(key: "type", value: LoggingEventType.mailRead)
        event.append(key: "from", value: mail.from)
        event.append(key: "to", value: Logger.resolve(mailAddresses: mail.to))
        event.append(key: "cc", value: Logger.resolve(mailAddresses: mail.cc ?? NSSet()))
        event.append(key: "bcc", value: Logger.resolve(mailAddresses: mail.bcc ?? NSSet()))
        event.append(key: "bodyLength", value: (mail.body ?? "").count)
        event.append(key: "isEncrypted", value: mail.isEncrypted)
        event.append(key: "decryptedBodyLength", value: (mail.decryptedBody ?? "").count)
        event.append(key: "decryptedWithOldPrivateKey", value: mail.decryptedWithOldPrivateKey)
        event.append(key: "isSigned", value: mail.isSigned)
        event.append(key: "isCorrectlySigned", value: mail.isCorrectlySigned)
        //TODO:
        //event.append(key: "signingKeyID", value: Logger.resolve(keyID: signingKeyID))
        //event.append(key: "myKeyID", value: Logger.resolve(keyID: myKeyID))
        
        
        
        //event.append(key: "secureAddresses", value: secureAddresses) //could mean the addresses, in this mail we have a key for
        //event.append(key: "encryptedForKeyIDs", value: Logger.resolve(keyIDs: encryptedForKeyIDs))
        
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
        //TODO: implement
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
    
    static func resolve(mailAddresses: NSSet) -> [String] {
        var result: [String] = []
        for addr in mailAddresses {
            result.append(resolve(mailAddress: addr as! MailAddress))
        }
        return result
    }
    
    static func resolve(mailAddresses: [String]) -> [String] {
        var result: [String] = []
        for addr in mailAddresses {
            result.append(resolve(mailAddress: addr))
        }
        return result
    }
    
    static func resolve(keyIDs: [String]) -> [String] {
        var result: [String] = []
        for id in keyIDs {
            result.append(resolve(keyID: id))
        }
        return result
    }
    
    static func saveToDisk() {
        
        var json = "some text"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(fileName)

            // reading
            do {
                let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
                if !currentContent.isEmpty {
                    json = "\(json)\n\(currentContent)"
                }
            }
            catch {
                print("Error while reading logfile: \(error.localizedDescription)")
            }
            // writing
            do {
                try json.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print("Error while writing logfile: \(error.localizedDescription)")
            }
            
        } else {
            print("No document folder?!")
        }
    }
    
    static func sendLog() {
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(fileName)
            
            // reading
            do {
                let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
                if !currentContent.isEmpty {
                    AppDelegate.getAppDelegate().mailHandler.send(["logMailAddress"], ccEntrys: [], bccEntrys: [], subject: "Log", message: currentContent, callback: sendCallback)
                }
            }
            catch {
                print("Error while reading logfile: \(error.localizedDescription)")
            }
        }
    }
    
    static func sendCallback(error: Error?) {
        guard error == nil else {
            print(error!)
            return
        }
        
        clearLog()
    }
    
    static func clearLog() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(fileName)
            
            do {
                try String().write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print("Error while clearing logfile: \(error.localizedDescription)")
            }
        }
    }
}

enum LogType: String {
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
