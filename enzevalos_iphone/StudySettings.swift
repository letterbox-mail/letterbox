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
    static var studyMode = false
    static var presentFirstQuestionaireMail = false
    
    static let faqURL = "https://userpage.fu-berlin.de/wieseoli/letterbox/faq.html"
    static let raffleURL = ""
    static var studyID: String{
        get{
            //TODO: Jakob
            return ""
        }
    }
    
    static var entrySurveyURL: String{
        get{
            return "https://userpage.fu-berlin.de/wieseoli/letterbox/presurvey.html?id=\(studyID)"
        }
    }

    
    static func setupStudy() {
        if !studyMode {
            //Logger.logging = false
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
            presentFirstQuestionaireMail = true
            UserDefaults.standard.set(studyID, forKey: "studyID")
            Logger.studyID = studyID
        } else {
            let studyID = String.random(length: 30)
            keychain["studyID"] = studyID
            UserDefaults.standard.set(studyID, forKey: "studyID")
        }
//        Logger.queue.async(flags: .barrier) {
            Logger.log(setupStudy: warnings, alreadyRegistered: presentFirstQuestionaireMail)
//        }
        
    }
    //create local mail for first interview here
    static func firstMail() -> PersistentMail?{
        let subject = "Herzlichen Willkommen in Letterbox"
        let body =
        """
        Liebe Teilnehmerin, lieber Teilnehmer,
        
        Herzlichen Glückwunsch Sie haben Letterbox erfolgreich installiert!
        Bitte nehmen Sie an einem Fragebogen mit maximal 10 Fragen über Ihre bisherigen Erfahrungen mit E-Mail-Verschlüsselung teil.
        Dazu folgen Sie bitte diesem Link:
        \(entrySurveyURL)
        
        Wenn Sie Fragen zur App oder Verschlüsselung haben, besuchen Sie doch unsere Hilfeseite:
        \(faqURL)
        
        Dort finden Sie auch Videos zum Thema Ende-Zu-Ende-Verschlüsselung.
        Falls Sie Fragen haben oder uns ein Feedback geben möchten, freuen wir uns auf Ihre E-Mail!
        
        Sie können einen ersten Brief verfassen in dem Sie auf diese E-Mail antworten.
        
        Vielen Dank für Ihre Teilnahme und mit freundlichen Grüßen
        Ihr Letterbox-Team
        
        PS: Diese Nachricht wurde automatisch auf in Ihrer Letterbox erzeugt und ist nur dort gespeichert.
        """
        return StudySettings.mailToParticipat(subject: subject, body: body)
    }
    
    static func givecards() -> PersistentMail?{
        let subject = "Teilnahmeentschädigung: Verlosung von Amazon-Gutscheinen"
        let body =
        """
        Liebe Teilnehmerin, lieber Teilnehmer,

        unter den teilnehmenden Personen werden 20 Amazon-Gutscheine im Wert von jeweils 50 Euro verlost.

        Um an der Verlosung teilnehmen zu können, müssen Sie bitte Ihren Namen und die postalische Adresse angeben.
        Falls Sie einen Gutschein gewinnen, wird dieser Ihnen per Post zu gesendet. Außerdem wird Ihr Name und Ihre Adresse für den Nachweis der ordnungsgemäßen Verwendung der Gelder gespeichert.
        
        Ihre Name und Ihre Adresse werden nicht mit anderen erhobenen Daten verknüpft und getrennt von diesen gespeichert.

        Wenn Sie an der Verlosung teilnehmen möchten, melden Sie sich bitte auf folgenden Link an:
        \(raffleURL)
        
        Vielen Dank für Ihre Teilnahme und mit freundlichen Grüßen#imageLiteral(resourceName: "onboardingOff")
        Ihr Letterbox-Team

        PS: Diese Nachricht wurde automatisch auf in Ihrer Letterbox erzeugt und ist nur dort gespeichert.
        """
        
        return mailToParticipat(subject: subject, body: body)
    }
    
    
    private static func mailToParticipat(subject: String, body: String) -> PersistentMail?{
        let senderAdr = SUPPORT_MAIL_ADR
        let sender = MCOAddress.init(displayName: "Letterbox-Team", mailbox: senderAdr)
        let signKey = "F3ADDC8B81F82CCEB534CFC766BA7478AD254666"//DataHandler.handler.findKey(keyID: senderAdr)
        
        let cryptoObject = CryptoObject(chiphertext: nil, plaintext: body, decryptedData: body.data(using: .utf8), sigState: SignatureState.ValidSignature, encState: EncryptionState.ValidedEncryptedWithCurrentKey, signKey: signKey, encType: CryptoScheme.PGP, signedAdrs: [senderAdr])
        
        return DataHandler.handler.createMail(0, sender: sender, receivers: [], cc: [], time: Date(), received: false, subject: subject, body: body, flags: MCOMessageFlag.init(rawValue: 0), record: nil, autocrypt: nil, decryptedData: cryptoObject, folderPath: UserManager.backendInboxFolderPath, secretKey: nil)
    }
    
    
}
