//
//  StudySettings.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 08.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation
import KeychainAccess

enum StudyParamter: Int {
    case Warning = 0
    case Invitation = 1
    
    var name: String{
        get{
            switch self {
            case .Warning:
                return "warning"
            case .Invitation:
                    return "invitation"
            }
        }
    }
    
    var fileDir: String {
        get{
            switch  self {
            case .Warning:
                return "hideWarnings"
            case .Invitation:
                return "invitation mode"
            }
        }
    }
    var variables: Int {
        get{
            switch self {
            case .Warning:
                return 2
            case .Invitation:
                return 4
            }
        }
    }
}

enum InvitationMode: Int {
    case FreeText = 0
    case InviteMail = 1
    case PasswordEnc = 2
    case Censorship = 3
}

class StudySettings {
    static var studyMode = true
    static var presentFirstQuestionaireMail = false
    static let parameters = [StudyParamter.Invitation]
    
    public static var invitationEnabled: Bool{
        get{
            return invitationsmode == InvitationMode.Censorship || invitationsmode == InvitationMode.PasswordEnc
        }
    }
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
    
    static var invitationsmode: InvitationMode{
        get{
            return InvitationMode.Censorship
            let value = UserDefaults.standard.integer(forKey: StudyParamter.Invitation.fileDir)
            if let mode = InvitationMode.init(rawValue: value){
                return mode
            }
            return InvitationMode.InviteMail
        }
    }
    
    
    private static var studyParameters: [StudyParamter:Int]{
        get{
            let keychain = Keychain(service: "Enzevalos/Study")
            var studyParamters = [StudyParamter: Int]()
            for parameter in parameters{
                var value: Int?
                if let state = keychain[parameter.fileDir], let num = Int(state) {
                    value = num
                }
                else {
                    value = Int(arc4random_uniform(UInt32(parameter.variables)))
                    if let value = value{
                        keychain[parameter.fileDir] = String(value)
                    }
                }
                if parameter == StudyParamter.Invitation{
                    //TODO: Remove @Olli
                    value = InvitationMode.Censorship.rawValue
                }
                if let v = value{
                    UserDefaults.standard.set(v, forKey: parameter.fileDir)
                    studyParamters[parameter] = v
                }
            }
            return studyParamters
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
        let keychain = Keychain(service: "Enzevalos/Study")
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
        let parameters = studyParameters
        
        
//        Logger.queue.async(flags: .barrier) {
        Logger.log(setupStudy: parameters, alreadyRegistered: !presentFirstQuestionaireMail, bitcoin: bitcoinMails)
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
