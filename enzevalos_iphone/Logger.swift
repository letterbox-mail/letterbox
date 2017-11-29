//
//  Logger.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 25.10.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

class Logger {
    
    static var logging = true//false
    
    static let defaultFileName = "log.json"
    static let loggingInterval = 86400 //60*60*24 seconds
    
    static var nextDeadline = (UserManager.loadUserValue(Attribute.nextDeadline) as? Date) ?? Date()
    
    static fileprivate func sendCheck() {
        if nextDeadline <= Date() {
            logInbox()
            logOverview()
            sendLog()
        }
    }
    
    static fileprivate func plainLogDict() -> [String: Any] {
        var fields: [String: Any] = [:]
        let now = Date()
        //TODO add uuid here
        fields["timestamp"] = now.description
        return fields
    }
    
    static fileprivate func dictToJSON(fields: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: fields)
            if let json = String(data: jsonData, encoding: String.Encoding.utf8) {
                return json
            }
            return ""
        } catch {
            return "{\"error\":\"json conversion failed\"}"
        }
    }
    
    static func log(startApp onboarding: Bool) {
        
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.appStart.rawValue
        event["onboarding"] = onboarding
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(terminateApp: Void) {
        if !logging {
            return
        }
        var event = plainLogDict()
        event["type"] = LoggingEventType.appTerminate.rawValue
        saveToDisk(json: dictToJSON(fields: event))
    }
    
    static func log(background goto: Bool) {
        
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.appBackground.rawValue
        event["going to"] = goto //true -> goto background; false -> comming from background
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(keyViewOpen keyID: String) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.keyViewOpen.rawValue
        event["keyID"] = resolve(keyID: keyID)
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(keyViewClose keyID: String, secondsOpened: Int) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.keyViewClose.rawValue
        event["keyID"] = resolve(keyID: keyID)
        event["opened for seconds"] = secondsOpened
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(sent from: String, to: [String], cc: [String], bcc: [String], bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, decryptedWithOldPrivateKey: Bool = false, isSigned: Bool, isCorrectlySigned: Bool = true, signingKeyID: String, myKeyID: String, secureAddresses: [String] = [], encryptedForKeyIDs: [String] = []) {
        
        if !logging {
            return
        }
        
        var event = plainLogDict()
        
        event["type"] = LoggingEventType.mailSent.rawValue
        event["from"] = Logger.resolve(mailAddress: from)
        event["to"] = Logger.resolve(mailAddresses: to)
        event["cc"] = Logger.resolve(mailAddresses: cc)
        event["bcc"] = Logger.resolve(mailAddresses: bcc)
        event["bodyLength"] = bodyLength
        event["isEncrypted"] = isEncrypted
        event["decryptedBodyLength"] = decryptedBodyLength
        event["decryptedWithOldPrivateKey"] = decryptedWithOldPrivateKey
        event["isSigned"] = isSigned
        event["isCorrectlySigned"] = isCorrectlySigned
        event["signingKeyID"] = Logger.resolve(keyID: signingKeyID)
        event["myKeyID"] = Logger.resolve(keyID: myKeyID)
        event["secureAddresses"] = Logger.resolve(mailAddresses:secureAddresses) //means the addresses, which received a secure mail
        event["encryptedForKeyIDs"] = Logger.resolve(keyIDs: encryptedForKeyIDs)
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(read from: String, to: [String], cc: [String], bcc: [String], bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, decryptedWithOldPrivateKey: Bool = false, isSigned: Bool, isCorrectlySigned: Bool = true, signingKeyID: String, myKeyID: String, secureAddresses: [String] = [], encryptedForKeyIDs: [String] = [], trouble: Bool) {
        
        if !logging {
            return
        }
        
        var event = plainLogDict()
        
        event["type"] = LoggingEventType.mailRead.rawValue
        event["from"] = Logger.resolve(mailAddress: from)
        event["to"] = Logger.resolve(mailAddresses: to)
        event["cc"] = Logger.resolve(mailAddresses: cc)
        event["bcc"] = Logger.resolve(mailAddresses: bcc)
        event["bodyLength"] = bodyLength
        event["isEncrypted"] = isEncrypted
        event["decryptedBodyLength"] = decryptedBodyLength
        event["decryptedWithOldPrivateKey"] = decryptedWithOldPrivateKey
        event["isSigned"] = isSigned
        event["isCorrectlySigned"] = isCorrectlySigned
        event["signingKeyID"] = Logger.resolve(keyID: signingKeyID)
        event["myKeyID"] = Logger.resolve(keyID: myKeyID)
        event["secureAddresses"] = Logger.resolve(mailAddresses: secureAddresses) //could mean the addresses, in this mail we have a key for
        event["encryptedForKeyIDs"] = Logger.resolve(keyIDs: encryptedForKeyIDs)
        event["trouble"] = trouble
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(read mail: PersistentMail, message: String) {
        var event = plainLogDict()
        
        if !logging {
            return
        }
        
        event["type"] = LoggingEventType.mailRead.rawValue
        event["from"] = Logger.resolve(mailAddress: mail.from.mailAddress)
        event["to"] = Logger.resolve(mailAddresses: mail.to)
        event["cc"] = Logger.resolve(mailAddresses: mail.cc ?? NSSet())
        event["bcc"] = Logger.resolve(mailAddresses: mail.bcc ?? NSSet())
        event["bodyLength"] = (mail.body ?? "").count
        event["isEncrypted"] = mail.isEncrypted
        event["decryptedBodyLength"] = (mail.decryptedBody ?? "").count
        event["decryptedWithOldPrivateKey"] = mail.decryptedWithOldPrivateKey
        event["isSigned"] = mail.isSigned
        event["isCorrectlySigned"] = mail.isCorrectlySigned
        //TODO:
        //event["signingKeyID"] = Logger.resolve(keyID: signingKeyID)
        //event["myKeyID"] = Logger.resolve(keyID: myKeyID)
        
        
        
        //event["secureAddresses"] = secureAddresses //could mean the addresses, in this mail we have a key for
        //event["encryptedForKeyIDs"] = Logger.resolve(keyIDs: encryptedForKeyIDs)
        
        event["trouble"] = mail.trouble
        event["messagePresented"] = message
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(received mail: PersistentMail) {
        var event = plainLogDict()
        
        if !logging {
            return
        }
        
        event["type"] = LoggingEventType.mailReceived.rawValue
        event["from"] = Logger.resolve(mailAddress: mail.from)
        event["to"] = Logger.resolve(mailAddresses: mail.to)
        event["cc"] = Logger.resolve(mailAddresses: mail.cc ?? NSSet())
        event["bcc"] = Logger.resolve(mailAddresses: mail.bcc ?? NSSet())
        event["bodyLength"] = (mail.body ?? "").count
        event["isEncrypted"] = mail.isEncrypted
        event["decryptedBodyLength"] = (mail.decryptedBody ?? "").count
        event["decryptedWithOldPrivateKey"] = mail.decryptedWithOldPrivateKey
        event["isSigned"] = mail.isSigned
        event["isCorrectlySigned"] = mail.isCorrectlySigned
        //TODO:
        //event["signingKeyID"] = Logger.resolve(keyID: signingKeyID)
        //event["myKeyID"] = Logger.resolve(keyID: myKeyID)
        
        
        
        //event["secureAddresses"] = secureAddresses //could mean the addresses, in this mail we have a key for
        //event["encryptedForKeyIDs"] = Logger.resolve(keyIDs: encryptedForKeyIDs)
        
        event["trouble"] = mail.trouble
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func logInbox() {
        var event = plainLogDict()
        
        event["type"] = LoggingEventType.overviewInbox.rawValue
        
        let inbox = DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath)
        event["nrOfMails"] = inbox.mailsOfFolder.count
        event["nrOfSecureMails"] = inbox.mailsOfFolder.reduce(0, { $1.isSecure ? $0 + 1: $0 }) as Int
        event["nrOfTroubleMails"] = inbox.mailsOfFolder.reduce(0, { $1.trouble ? $0 + 1: $0 }) as Int
        
        saveToDisk(json: dictToJSON(fields: event))
    }
    
    static fileprivate func calculateOverview() {
        /*let contacts: [EnzevalosContact] = DataHandler.handler.getContacts()
        //let contactCount = contacts.count
    
        var secureContactsCount: Int = 0
    
        var secureMailsReceived: Int = 0
        var secureMailsSent: Int = 0
        var signedMailsReceived: Int = 0
        var signedMailsSent: Int = 0
        var encryptedMailsReceived: Int = 0
        var encryptedMailsSent: Int = 0
    
        var mailsSent : Int = 0
        var mailsReceived : Int = 0
    
        for contact in contacts {
            if contact.hasKey { secureContactsCount += 1 }
    
            var mailsTo : [PersistentMail] = contact.to
            mailsTo.append(contentsOf: contact.cc)
            mailsTo.append(contentsOf: contact.bcc)
    
            //WTF Mails von mir an mich zählen doppelt?! Mails, die an mehrere Kontakte gingen ebenfalls?
            
            let mailsFrom : [PersistentMail] = contact.from
    
            for mail in mailsTo {
                if mail.isSecure {
                    secureMailsSent += 1
                } else {
                    mailsSent += 1
                }
                
                if mail.isEncrypted {
                    encryptedMailsSent += 1
                }
            }
    
            for mail in mailsFrom {
                if mail.isSecure {
                    secureMailsReceived += 1
                } else {
                    mailsReceived += 1
                }
            }
        }
    
        let mailsCount : Int = mailsSend + secureMailsSend + mailsReceived + secureMailsReceived
        let secureMailsCount : Int = secureMailsReceived + secureMailsSend
        let totalMails : Int = mailsCount + secureMailsCount
    
        let a = contacts.count == 0 ? 0 : Float(secureContactsCount) / Float(contacts.count)
        let b = totalMails == 0 ? 0 : Float(secureMailsCount) / Float(totalMails)
        return ( a, b )*/
    }
        
    static func logOverview() {
        
        var event = plainLogDict()
        
        event["type"] = LoggingEventType.overviewGeneral.rawValue
        event["nrOfFolders"] = DataHandler.handler.allFolders.count
        let gesendet = DataHandler.handler.findFolder(with: UserManager.backendSentFolderPath)
        event["nrOfGesendetMails"] = gesendet.mailsOfFolder.count //@Olli: should we fetch the counter before?
        let (contact,mail) = GamificationData.sharedInstance.getSecureProgress()
        
        saveToDisk(json: dictToJSON(fields: event))
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
        return DataHandler.handler.getPseudonymKey(keyID: keyID).pseudonym
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
    
    static func saveToDisk(json: String, fileName: String = defaultFileName) {
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: fileURL.path) {
                // append
                do {
                    let fileHandle = try FileHandle(forUpdating: fileURL)
                    
                    fileHandle.seekToEndOfFile()
                    if let encoded = "\n\(json),".data(using: .utf8) {
                        fileHandle.write(encoded)
                    }
                    fileHandle.closeFile()
                }
                catch {
                    print("Error while appending to logfile: \(error.localizedDescription)")
                }
            } else {
                // write new
                do {
                    try json.write(to: fileURL, atomically: false, encoding: .utf8)
                }
                catch {
                    print("Error while writing logfile: \(error.localizedDescription)")
                }
            }
            
        } else {
            print("No document folder?!")
        }
    }
    
    static func sendLog(fileName: String = defaultFileName, logMailAddress: String = "oliver.wiese@fu-berlin.de") {
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(fileName)
            
            // reading
            do {
                let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
                if !currentContent.isEmpty {
                    AppDelegate.getAppDelegate().mailHandler.send([logMailAddress], ccEntrys: [], bccEntrys: [], subject: "[Enzevalos] Log", message: "["+currentContent.dropLast()+"\n]", callback: sendCallback, logMail: false)
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
        let tmpNextDeadline = Date(timeIntervalSinceNow: TimeInterval(loggingInterval))
            nextDeadline = tmpNextDeadline
            UserManager.storeUserValue(nextDeadline as AnyObject?, attribute: Attribute.nextDeadline)
    }
    
    static func clearLog(fileName: String = defaultFileName) {
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
