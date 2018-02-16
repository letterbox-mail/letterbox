//
//  StudySettings.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 08.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation
import KeychainAccess

class StudySettings {
    static var studyMode = true
    static var presentFirstQuestionaireMail = true
    
    static let faqURL = "https://userpage.fu-berlin.de/wieseoli/letterbox/faq.html"
    static let raffleURL = ""
    static var studyID: String {
        return UserDefaults.standard.string(forKey: "studyID") ?? ""
    }
    
    static var entrySurveyURL: String{
        get{
            return "https://userpage.fu-berlin.de/wieseoli/letterbox/entrysurvey.html?id=\(studyID)"
        }
    }
    static var bitcoinMails: Bool { //do we recived a mail from bitcoin.de
        get {
            return UserDefaults.standard.bool(forKey: "bitcoin")
        }
        set(newBool) {
            if !UserDefaults.standard.bool(forKey: "bitcoin") && newBool {
                let keychain = Keychain(service: "Enzevalos/Study")
                keychain["bitcoin"] = "true"
                UserDefaults.standard.set(true, forKey: "bitcoin")
//                Logger.queue.async(flags: .barrier) {
                    Logger.log(bitcoinMail: true)
//                }
            }
        }
    }
    
    static func setupStudy() {
        if !studyMode {
            //Logger.logging = false
            return
        }
        if UserDefaults.standard.string(forKey: "studyID") != nil && UserDefaults.standard.string(forKey: "hideWarnings") != nil { //no need to refill this fields, they are already loaded
            return
        }
        Logger.logging = true
        
        var warnings = true
        let keychain = Keychain(service: "Enzevalos/Study")
        if let state = keychain["hideWarnings"] {
            warnings = Bool(state)!
        } else {
            var randomBytes = Data(count: 1)
            let result = randomBytes.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, $0)
            }
            if result == errSecSuccess {
                warnings = randomBytes[0] >= 128
            } else {
                print("Problem generating random bytes")
                warnings = Int(arc4random_uniform(2)) == 0
            }
            keychain["hideWarnings"] = String(warnings)
        }
        UserDefaults.standard.set(warnings, forKey: "hideWarnings")
        
        if let studyID = keychain["studyID"] {
            UserDefaults.standard.set(studyID, forKey: "studyID")
            Logger.studyID = studyID
        } else {
            let studyID = String.random(length: 30)
            presentFirstQuestionaireMail = true
            keychain["studyID"] = studyID
            UserDefaults.standard.set(studyID, forKey: "studyID")
        }
        
        if let bitcoin = keychain["bitcoin"] { //do we received a mail from bitcoin.de?
            UserDefaults.standard.set(Bool(bitcoin) ?? false, forKey: "bitcoin")
        } else {
            keychain["bitcoin"] = "false"
            UserDefaults.standard.set(false, forKey: "bitcoin")
        }
        
        
//        Logger.queue.async(flags: .barrier) {
        Logger.log(setupStudy: warnings, alreadyRegistered: !presentFirstQuestionaireMail, bitcoin: bitcoinMails)
//        }
        
    }
    //create local mail for first interview here
    static func firstMail() {
        if !studyMode || !presentFirstQuestionaireMail {
            return
        }
        let subject = "Herzlich Willkommen in Letterbox"
        let body =
        """
        Liebe Teilnehmerin, lieber Teilnehmer,
        
        Herzlichen Glückwunsch! Sie haben Letterbox erfolgreich installiert.
        
        Wir haben einen Eingangsfragebogen mit maximal 10 Fragen über Ihre bisherigen Erfahrungen mit E-Mail-Verschlüsselung vorbereitet und würden Sie bitten diesen auszufüllen.
        Dazu folgen Sie bitte folgendem Link:
        \(entrySurveyURL)
        
        Wenn Sie Fragen zur App oder Verschlüsselung haben, besuchen Sie doch unsere Hilfeseite:
        \(faqURL)
        
        Dort finden Sie auch Videos zum Thema Ende-zu-Ende-Verschlüsselung.
        Falls Sie Fragen haben oder uns Feedback geben möchten, freuen wir uns auf Ihre E-Mail!
        
        Verfassen Sie doch einen ersten Brief, indem Sie auf diese E-Mail antworten und uns Ihre Erfahrungen, Fragen oder Kommentare mitteilen. Ist etwas unklar geblieben? Was war Ihnen neu? Hätten Sie sich sonst noch etwas gewünscht?
        
        Vielen Dank für Ihre Teilnahme und mit freundlichen Grüßen,
        Ihr Letterbox-Team
        
        PS: Diese Nachricht wurde automatisch in Letterbox erzeugt und ist nur hier gespeichert.
        """
        mailToParticipat(subject: subject, body: body)
    }
    
    static func givecards() {
        if !studyMode || !presentFirstQuestionaireMail {
            return
        }
        let subject = "Teilnahmeentschädigung: Verlosung von Amazon-Gutscheinen"
        let body =
        """
        Liebe Teilnehmerin, lieber Teilnehmer,

        unter den teilnehmenden Personen werden 20 Amazon-Gutscheine im Wert von jeweils 50 Euro verlost.

        Um an der Verlosung teilnehmen zu können, müssen Sie uns Ihren Namen und die postalische Adresse mitteilen.
        Falls Sie einen Gutschein gewinnen, wird dieser Ihnen per Post zugesendet. Außerdem werden Ihr Name und Ihre Adresse für den Nachweis der ordnungsgemäßen Verwendung der Gelder gespeichert, andernfalls werden sie gelöscht.
        
        Ihre Name und Ihre Adresse werden nicht mit anderen erhobenen Daten verknüpft und getrennt von diesen gespeichert.

        Wenn Sie an der Verlosung teilnehmen möchten, melden Sie sich bitte auf folgenden Link an:
        \(raffleURL)
        
        Vielen Dank für Ihre Teilnahme und mit freundlichen Grüßen,
        Ihr Letterbox-Team

        PS: Diese Nachricht wurde automatisch in Letterbox erzeugt und ist nur hier gespeichert.
        """
        
        mailToParticipat(subject: subject, body: body)
    }
    
    
    private static func mailToParticipat(subject: String, body: String){
        let senderAdr = SUPPORT_MAIL_ADR
        let sender = MCOAddress.init(displayName: "Letterbox-Team", mailbox: senderAdr)
        var keyID: String?
        if let addr = DataHandler.handler.findMailAddress(adr: senderAdr){
            if let pk = addr.primaryKey{
                keyID = pk.keyID
            }
        }
        let cryptoObject = CryptoObject(chiphertext: nil, plaintext: body, decryptedData: body.data(using: .utf8), sigState: SignatureState.ValidSignature, encState: EncryptionState.ValidedEncryptedWithCurrentKey, signKey: keyID, encType: CryptoScheme.PGP, signedAdrs: [senderAdr])
        
        _ = DataHandler.handler.createMail(0, sender: sender, receivers: [], cc: [], time: Date(), received: false, subject: subject, body: body, flags: MCOMessageFlag.init(rawValue: 0), record: nil, autocrypt: nil, decryptedData: cryptoObject, folderPath: UserManager.backendInboxFolderPath, secretKey: nil)
    }
    
    public static func setupStudyKeys() {
        if studyMode || Logger.logging {
            setupStudyPublicKeys()
        }
    }
    
}
