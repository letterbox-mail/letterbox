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

    static let queue = DispatchQueue(label: "logging", qos: .background)

    static let defaultFileName = "log.json"
    static let loggingInterval = 21600 //60*60*6 seconds
    static let resendInterval = 5*60
    static let logReceiver = LOGGING_MAIL_ADR

    static var nextDeadline = (UserManager.loadUserValue(Attribute.nextDeadline) as? Date) ?? Date()
    
    static var studyID = StudySettings.studyID //identifies the participant in the study

    static fileprivate func sendCheck() {
        if nextDeadline <= Date() && AppDelegate.getAppDelegate().currentReachabilityStatus != .notReachable {
            //Do not send duplicate mails
            let tmpNextDeadline = Date(timeIntervalSinceNow: TimeInterval(resendInterval))
            nextDeadline = tmpNextDeadline
            UserManager.storeUserValue(nextDeadline as AnyObject?, attribute: Attribute.nextDeadline)
            
            sendLog()
        }
    }

    static fileprivate func plainLogDict() -> [String: Any] {
        var fields: [String: Any] = [:]
        let now = Date()
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

    static func log(setupStudy hideWarnings: Bool, alreadyRegistered: Bool, bitcoin: Bool) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.setupStudy.rawValue
        event["hideWarnings"] = hideWarnings
        event["alreadyRegistered"] = alreadyRegistered
        event["bitcoinMailReceived"] = bitcoin
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
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

    static func log(contactViewOpen keyRecord: KeyRecord?, otherRecords: [KeyRecord]?, isUser: Bool) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.contactViewOpen.rawValue

        if let keyRecord = keyRecord {
            if let keyID = keyRecord.keyID {
                event["keyID"] = resolve(keyID: keyID)
            } else {
                event["keyID"] = "nil"
            }
            event["mailaddresses"] = resolve(mailAddresses: keyRecord.addresses)
        }
        event["isUser"] = isUser
        if isUser {
            let (contact, mail) = GamificationData.sharedInstance.getSecureProgress()
            event["gamificationContact"] = contact
            event["gamificationMail"] = mail
        }
        event["numberOfOtherRecords"] = (otherRecords ?? []).count
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(badgeCaseViewOpen badges: [Badges]) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.badgeCaseViewOpen.rawValue

        var achievedBadges: [String] = []
        var missingBadges: [String] = []

        for badge in badges {
            if badge.isAchieved() {
                achievedBadges.append(badge.displayName)
            } else {
                missingBadges.append(badge.displayName)
            }
        }

        event["achievedBadges"] = achievedBadges
        event["missingBadges"] = missingBadges

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(badgeCaseViewClose badges: [Badges]) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.badgeCaseViewClose.rawValue

        var achievedBadges: [String] = []
        var missingBadges: [String] = []

        for badge in badges {
            if badge.isAchieved() {
                achievedBadges.append(badge.displayName)
            } else {
                missingBadges.append(badge.displayName)
            }
        }

        event["achievedBadges"] = achievedBadges
        event["missingBadges"] = missingBadges

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(contactViewClose keyRecord: KeyRecord?, otherRecords: [KeyRecord]?, isUser: Bool) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.contactViewClose.rawValue

        if let keyRecord = keyRecord {
            if let keyID = keyRecord.keyID {
                event["keyID"] = resolve(keyID: keyID)
            } else {
                event["keyID"] = "nil"
            }
            event["mailaddresses"] = resolve(mailAddresses: keyRecord.addresses)
        }
        event["isUser"] = isUser
        if isUser {
            let (contact, mail) = GamificationData.sharedInstance.getSecureProgress()
            event["gamificationContact"] = contact
            event["gamificationMail"] = mail
        }
        event["numberOfOtherRecords"] = (otherRecords ?? []).count
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
    
    static func log(exportKeyViewOpen view: Int) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.exportKeyViewOpen.rawValue
        event["view"] = view
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(exportKeyViewClose view: Int) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.exportKeyViewClose.rawValue
        event["view"] = view
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(exportKeyViewButton send: Bool) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.exportKeyViewClose.rawValue
        if send {
            event["case"] = "sendMail"
        } else {
            event["case"] = "deletePasscode"
        }
            
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(importPrivateKeyPopupOpen mail: PersistentMail?) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.importPrivateKeyPopupOpen.rawValue
        if let mail = mail {
            event = extract(from: mail, event: event)
        }
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(importPrivateKeyPopupClose mail: PersistentMail?, doImport: Bool) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.importPrivateKeyPopupClose.rawValue
        event["doImport"] = doImport
        if let mail = mail {
            event = extract(from: mail, event: event)
        }
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(importPrivateKey mail: PersistentMail?, success: Bool) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.importPrivateKey.rawValue
        event["success"] = success
        if let mail = mail {
            event = extract(from: mail, event: event)
        }
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(sendViewOpen mail: EphemeralMail?) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.sendViewOpen.rawValue
        if let mail = mail {
            event = extract(from: mail, event: event)
        }
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(sendViewClose mail: EphemeralMail?) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.sendViewClose.rawValue
        if let mail = mail {
            event = extract(from: mail, event: event)
        }
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(createDraft to: [Mail_Address?], cc: [Mail_Address?], bcc: [Mail_Address?], subject: String, bodyLength: Int, isEncrypted: Bool, isSigned: Bool, myKeyID: String) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.createDraft.rawValue
        
        
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(sent from: Mail_Address, to: [Mail_Address], cc: [Mail_Address], bcc: [Mail_Address], subject: String, bodyLength: Int, isEncrypted: Bool, decryptedBodyLength: Int, decryptedWithOldPrivateKey: Bool = false, isSigned: Bool, isCorrectlySigned: Bool = true, signingKeyID: String, myKeyID: String, secureAddresses: [Mail_Address] = [], encryptedForKeyIDs: [String] = []) {

        if !logging {
            return
        }

        var event = plainLogDict()

        event["type"] = LoggingEventType.mailSent.rawValue
        event["from"] = Logger.resolve(mailAddress: from)
        event["to"] = Logger.resolve(mailAddresses: to)
        event["cc"] = Logger.resolve(mailAddresses: cc)
        event["bcc"] = Logger.resolve(mailAddresses: bcc)
        event["communicationState"] = Logger.communicationState(subject: subject)
        event["specialMail"] = Logger.specialMail(subject: subject)
        event["bodyLength"] = bodyLength
        event["isEncrypted"] = isEncrypted
        event["decryptedBodyLength"] = decryptedBodyLength
        event["decryptedWithOldPrivateKey"] = decryptedWithOldPrivateKey
        event["isSigned"] = isSigned
        event["isCorrectlySigned"] = isCorrectlySigned
        event["signingKeyID"] = Logger.resolve(keyID: signingKeyID)
        event["myKeyID"] = Logger.resolve(keyID: myKeyID)
        event["secureAddresses"] = Logger.resolve(mailAddresses: secureAddresses) //means the addresses, which received a secure mail
        event["encryptedForKeyIDs"] = Logger.resolve(keyIDs: encryptedForKeyIDs)

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(read mail: PersistentMail, message: String, open: Bool) {
        if !logging {
            return
        }

        var event = plainLogDict()

        // TODO TO not extract if closing a mail!
        event["type"] = LoggingEventType.mailRead.rawValue
        if !open{
            event = extract(from: mail, event: event)
        }
        event["messagePresented"] = message
        event["open"] = open

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(readDraft mail: PersistentMail, message: String, open: Bool) {
        if !logging {
            return
        }

        var event = plainLogDict()

        event["type"] = LoggingEventType.mailDraftRead.rawValue
        event = extract(from: mail, event: event)
        event["messagePresented"] = message
        event["open"] = open

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(received mail: PersistentMail) {
        if !logging {
            return
        }

        var event = plainLogDict()

        event["type"] = LoggingEventType.mailReceived.rawValue
        event = extract(from: mail, event: event)

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(bitcoinMail gotIt: Bool) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        
        event["type"] = LoggingEventType.gotBitcoinMail.rawValue
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    

    static func log(delete mail: PersistentMail, toTrash: Bool) {
        if !logging {
            return
        }

        var event = plainLogDict()
        if toTrash {
            event["type"] = LoggingEventType.mailDeletedToTrash.rawValue
        } else {
            event["type"] = LoggingEventType.mailDeletedPersistent.rawValue
        }
       // event = extract(from: mail, event: event)
        event["operation"] = "DeleteMail"

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(archive mail: PersistentMail) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.mailArchived.rawValue
        event = extract(from: mail, event: event)

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(open indicatorButton: String, mail: PersistentMail?) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.indicatorButtonOpen.rawValue
        event["indicatorButton"] = indicatorButton
        if let mail = mail {
            event["view"] = "readView"
            event = extract(from: mail, event: event)
        } else {
            event["view"] = "sendView"
        }

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(close indicatorButton: String, mail: PersistentMail?, action: String) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.indicatorButtonClose.rawValue
        event["indicatorButton"] = indicatorButton
        if let mail = mail {
            event["view"] = "readView"
            event = extract(from: mail, event: event)
        } else {
            event["view"] = "sendView"
        }
        event["action"] = action

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(showBroken mail: PersistentMail?) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.showBrokenMail.rawValue
        event["view"] = "readView"
        if let mail = mail {
            event = extract(from: mail, event: event)
        }

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }
    
    static func log(reactTo mail: PersistentMail?) {
        if !logging {
            return
        }
        
        var event = plainLogDict()
        event["type"] = LoggingEventType.reactButtonTapped.rawValue
        if let mail = mail {
            event = extract(from: mail, event: event)
        }
        
        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(discover publicKeyID: String, mailAddress: Mail_Address, importChannel: String, knownPrivateKey: Bool, knownBefore: Bool) { //add reference to mail here?
        if !logging {
            return
        }

        var event = plainLogDict()
        if !knownBefore {
            event["type"] = LoggingEventType.pubKeyDiscoveryNewKey.rawValue
        } else {
            event["type"] = LoggingEventType.pubKeyDiscoveryKnownKey.rawValue
        }
        event["keyID"] = Logger.resolve(keyID: publicKeyID)
        event["mailAddress"] = Logger.resolve(mail_address: mailAddress)
        event["knownPrivateKey"] = knownPrivateKey //Do we have a private key for it?
        event["importChannel"] = importChannel

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static func log(verify keyID: String, open: Bool, success: Bool? = nil) {
        if !logging {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.pubKeyVerification.rawValue
        event["keyID"] = Logger.resolve(keyID: keyID)
        var stateString = "open"
        if !open {
            stateString = "close"
        }
        event["state"] = stateString
        if let success = success {
            event["success"] = success
        }

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    /**
     - parameters:
        - nrOfTrays: Number of search results
        - category: 0 is sender, 1 is subject, 2 is message, 3 is everything
        - opened:   "mail" User opened a message,
                    "mailList" User opened the mail list,
                    "contact" User opened contact view,
                    "searchedInMailList" User searched in the ListView.
        - keyRecordMailList: Array of MailAddresses that identify the KeyRecord in which the user searched. Nil when not in MailListView.
     */
    static func log(search nrOfTrays: Int, category: Int, opened: String, keyRecordMailList: [MailAddress]? = nil) {
        guard logging else {
            return
        }

        var event = plainLogDict()
        event["type"] = LoggingEventType.search.rawValue
        event["category"] = category
        event["nrOfTrays"] = nrOfTrays
        event["opened"] = opened
        event["keyRecordMailList"] = resolve(mailAddresses: keyRecordMailList ?? [])

        saveToDisk(json: dictToJSON(fields: event))
        sendCheck()
    }

    static fileprivate func extract(from mail: PersistentMail, event: [String: Any]) -> [String: Any] {
        var event = event
        event["from"] = Logger.resolve(mailAddress: mail.from)
        event["to"] = Logger.resolve(mailAddresses: mail.to)
        event["cc"] = Logger.resolve(mailAddresses: mail.cc ?? NSSet())
        event["bcc"] = Logger.resolve(mailAddresses: mail.bcc ?? NSSet())
        event["communicationState"] = Logger.communicationState(subject: mail.subject ?? "")
        event["specialMail"] = Logger.specialMail(subject: mail.subject ?? "")
        event["timeInHeader"] = mail.date.description
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
        event["folder"] = Logger.resolve(folder: mail.folder)

        return event
    }
    
    static fileprivate func extract(from mail: EphemeralMail, event: [String: Any]) -> [String: Any] {
        var event = event
        event["to"] = Logger.resolve(mailAddresses: mail.to)
        event["cc"] = Logger.resolve(mailAddresses: mail.cc ?? NSSet())
        event["bcc"] = Logger.resolve(mailAddresses: mail.bcc ?? NSSet())
        event["communicationState"] = Logger.communicationState(subject: mail.subject ?? "")
        event["specialMail"] = Logger.specialMail(subject: mail.subject ?? "")
        event["bodyLength"] = (mail.body ?? "").count
        //TODO:
        //event["signingKeyID"] = Logger.resolve(keyID: signingKeyID)
        //event["myKeyID"] = Logger.resolve(keyID: myKeyID)
        
        
        
        //event["secureAddresses"] = secureAddresses //could mean the addresses, in this mail we have a key for
        //event["encryptedForKeyIDs"] = Logger.resolve(keyIDs: encryptedForKeyIDs)
        
        return event
    }

    static func communicationState(subject: String) -> String {
        if subject == "" {
            return ""
        }
        var oldSubject = subject
        var newSubject = ""
        var hasPrefix = true

        while hasPrefix {
            if oldSubject.hasPrefix("Re: ") || oldSubject.hasPrefix("RE: ") || oldSubject.hasPrefix("re: ") || oldSubject.hasPrefix("AW: ") || oldSubject.hasPrefix("Aw: ") || oldSubject.hasPrefix("aw: ") {
                newSubject += "Re: "
                oldSubject = oldSubject.substring(from: oldSubject.index(oldSubject.startIndex, offsetBy: 4)) //damn swift3!
            } else if oldSubject.hasPrefix("Fwd: ") || oldSubject.hasPrefix("FWD: ") || oldSubject.hasPrefix("fwd: ") {
                newSubject += "Fwd: "
                oldSubject = oldSubject.substring(from: oldSubject.index(oldSubject.startIndex, offsetBy: 5))
            } else if oldSubject.hasPrefix("WG: ") || oldSubject.hasPrefix("Wg: ") || oldSubject.hasPrefix("wg: ") {
                newSubject += "Fwd: "
                oldSubject = oldSubject.substring(from: oldSubject.index(oldSubject.startIndex, offsetBy: 4))
            } else {
                hasPrefix = false
            }
        }

        return newSubject
    }
    
    static func specialMail(subject: String) -> String {
        if subject.contains(NSLocalizedString("inviteSubject", comment: "subject of invitation email")) {
            return "invitation"
        }
        return ""
    }

    //takes backendFolderPath
    static func resolve(folder: Folder) -> String {
        let folderPath = folder.path
        if folderPath == UserManager.backendSentFolderPath {
            return "sent"
        }
        if folderPath == UserManager.backendDraftFolderPath {
            return "draft"
        }
        if folderPath == UserManager.backendInboxFolderPath {
            return "inbox"
        }
        if folderPath == UserManager.backendTrashFolderPath {
            return "trash"
        }
        if folderPath == UserManager.backendArchiveFolderPath {
            return "archive"
        }
        return folder.pseudonym
    }

    //get an pseudonym for a mailAddress
    static func resolve(mailAddress: MailAddress) -> String {
        if let addr = mailAddress as? Mail_Address {
            return resolve(mail_address: addr)
        } else if mailAddress is CNMailAddressExtension {
            return "CNMailAddress"
        }
        return "unknownMailAddressType"
    }

    static func resolve(mail_address: Mail_Address) -> String {
        if mail_address.mailAddress == UserManager.loadUserValue(.userAddr) as? String ?? "" {
            return "self"//mail_address.mailAddress
        }
        return mail_address.pseudonym
    }

    static func resolve(mailAddresses: NSSet) -> [String] {
        var result: [String] = []
        for addr in mailAddresses {
            if let addr = addr as? Mail_Address {
                result.append(resolve(mail_address: addr))
            } else if addr is CNMailAddressExtension {
                result.append("CNMailAddress")
            } else {
                result.append("unknownMailAddressType")
            }
        }
        return result
    }

    static func resolve(mailAddresses: [Mail_Address]) -> [String] {
        var result: [String] = []
        for addr in mailAddresses {
            result.append(resolve(mail_address: addr))
        }
        return result
    }

    static func resolve(mailAddresses: [MailAddress]) -> [String] {
        var result: [String] = []
        for addr in mailAddresses {
            if let addr = addr as? Mail_Address {
                result.append(resolve(mail_address: addr))
            } else if addr is CNMailAddressExtension {
                result.append("CNMailAddress")
            } else {
                result.append("unknownMailAddressType")
            }
        }
        return result
    }

    //get an pseudonym for a keyID
    static func resolve(keyID: String) -> String {
        if let key = DataHandler.handler.findKey(keyID: keyID) {
            return key.pseudonym
        }
        return "noKeyID"
    }

    static func resolve(key: PersistentKey) -> String {
        return key.pseudonym
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

    static func sendLog(fileName: String = defaultFileName, logMailAddress: String = logReceiver) {

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(fileName)

            // reading
            do {
                let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
                if !currentContent.isEmpty {
                    AppDelegate.getAppDelegate().mailHandler.send([logMailAddress], ccEntrys: [], bccEntrys: [], subject: "[Enzevalos] Log", message: "{\"studyID\":\""+studyID+"\",\"data\":" + "[" + currentContent.dropLast() + "\n]" + "}", callback: sendCallback, loggingMail: true)
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
