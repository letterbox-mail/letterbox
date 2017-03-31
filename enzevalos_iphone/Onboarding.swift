//
//  Onboarding.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 29.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Onboard

class Onboarding {
    static var mailaddress = UITextField.init()
    static var username = UITextField.init()
    static var password = UITextField.init()
    static var imapServer = UITextField.init()
    static var smtpServer = UITextField.init()
    static var imapPort = UITextField.init()
    static var smtpPort = UITextField.init()
    static var imapAuthentication = UIPickerView.init()
    static var imapTransportEncryption = UIPickerView.init()
    static var smtpAuthentication = UIPickerView.init()
    static var smtpTransportEncryption = UIPickerView.init()
    static var background = UIImage.init()
    static var smtpCheck = false
    static var smtpCheckDone = false
    static var imapCheck = false
    static var imapCheckDone = false
    static var manualSet = false
    
    static var fail : () -> () = {Void in}
    static var work : () -> () = {Void in}

    static var authenticationRows : [Int : String] = [MCOAuthType.SASLNone.rawValue : "Keine", MCOAuthType.SASLLogin.rawValue : "Login", MCOAuthType.SASLPlain.rawValue : "Normal, Password", MCOAuthType.SASLSRP.rawValue : "SRP", MCOAuthType.SASLCRAMMD5.rawValue : "CRAMMD5", MCOAuthType.SASLDIGESTMD5.rawValue : "DIGESTMD5", MCOAuthType.SASLNTLM.rawValue : "NTLM", MCOAuthType.SASLGSSAPI.rawValue : "GSSAPI", MCOAuthType.SASLKerberosV4.rawValue : "KerberosV4"]
    
    static func onboarding(callback: dispatch_block_t) -> UIViewController {
        
        //Background
        
        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, false, 2) //try 200 here
        
        let context = UIGraphicsGetCurrentContext()
        
        //
        // Clip context to a circle
        //
        let path = CGPathCreateWithEllipseInRect(myBounds, nil);
        CGContextAddPath(context!, path);
        CGContextClip(context!);
        
        
        //
        // Fill background of context
        //
        CGContextSetFillColorWithColor(context!, UIColor.init(red: 0.1, green: 1.0, blue: 0.3, alpha: 0.0).CGColor)
        CGContextFillRect(context!, CGRectMake(0, 0, myBounds.size.width, myBounds.size.height));
        
        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        background = snapshot!
        
        //Content
        let page1 = OnboardingContentViewController.contentWithTitle("Hallo", body: "Schön, dass du dich für sichere Email interessierst!", image: nil, buttonText: "", action: nil)
        mailaddress = UITextField.init()
        //text.textColor = UIColor.whiteColor()
        //text.tintColor = UIColor.whiteColor()
        mailaddress.borderStyle = UITextBorderStyle.RoundedRect
        mailaddress.keyboardType = UIKeyboardType.EmailAddress
        mailaddress.autocorrectionType = UITextAutocorrectionType.No
        mailaddress.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        mailaddress.placeholder = "Adresse"
        let page2 = OnboardingContentViewController.contentWithTitle(nil, body: "Bitte gib deine Emailadresse ein", videoURL: nil, inputView: mailaddress, buttonText: nil, actionBlock: nil)
        
        password = UITextField.init()
        //text.textColor = UIColor.whiteColor()
        //text.tintColor = UIColor.whiteColor()
        password.borderStyle = UITextBorderStyle.RoundedRect
        password.secureTextEntry = true
        password.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        password.placeholder = "Passwort"
        let page3 = OnboardingContentViewController.contentWithTitle(nil, body: "Bitte gib\ndein Passwort ein", videoURL: nil, inputView: password, buttonText: nil, actionBlock: nil)
        let page4 = OnboardingContentViewController.contentWithTitle("Alles richtig?", body: nil, videoURL: nil, inputView: nil, buttonText: "Weiter", actionBlock: callback)
        
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1, page2, page3, page4])
    }
    
    static func checkConfigView() -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.contentWithTitle("Verbinde zum Mailserver", body: nil, videoURL: nil, inputView: view, buttonText: nil, actionBlock: nil)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
    }
    
    static func keyHandlingView() -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.contentWithTitle("Erstelle und verwalte Schlüssel", body: nil, videoURL: nil, inputView: view, buttonText: nil, actionBlock: nil)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
    }
    
    static func detailOnboarding(callback: dispatch_block_t) -> UIViewController {
        
        let font = UIFont.init(name: "Helvetica-Light", size: 28)
        let padding : CGFloat = 30
        
        let start = OnboardingContentViewController.contentWithTitle("Schade!", body: "Die Verbindung zum Server konnte nicht hergestellt werden. Bitte überprüfe die folgenden Angaben und passe sie ggf. an.", videoURL: nil, inputView: nil, buttonText: nil, actionBlock: nil)
        
        
        let email = OnboardingContentViewController.contentWithTitle(nil, body: "Bitte gib deine Emailadresse ein", videoURL: nil, inputView: mailaddress, buttonText: nil, actionBlock: nil)
        
        username = UITextField.init()
        //text.textColor = UIColor.whiteColor()
        //text.tintColor = UIColor.whiteColor()
        username.borderStyle = UITextBorderStyle.RoundedRect
        username.keyboardType = UIKeyboardType.EmailAddress
        username.autocorrectionType = UITextAutocorrectionType.No
        username.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        username.placeholder = "Nutzername"
        username.text = UserManager.loadUserValue(Attribute.UserName) as? String
        
        let user = OnboardingContentViewController.contentWithTitle(nil, body: "Bitte gib deinen Nutzernamen ein", videoURL: nil, inputView: username, buttonText: nil, actionBlock: nil)
        
        let passwd = OnboardingContentViewController.contentWithTitle(nil, body: "Bitte gib\ndein Passwort ein", videoURL: nil, inputView: password, buttonText: nil, actionBlock: nil)
        
        imapServer.borderStyle = UITextBorderStyle.RoundedRect
        imapServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        imapServer.text = UserManager.loadUserValue(Attribute.IMAPHostname) as? String
        
        let imapLabel = UILabel.init()
        imapLabel.text = "IMAP-Port"
        
        imapLabel.textColor = UIColor.whiteColor();
        imapLabel.font = font
        imapLabel.numberOfLines = 0;
        imapLabel.textAlignment = NSTextAlignment.Center;
        imapLabel.frame = CGRect.init(x: 0, y: imapServer.frame.height+padding, width: 50, height: 30)
        imapPort.borderStyle = UITextBorderStyle.RoundedRect
        imapPort.text = "0"
        if let port = UserManager.loadUserValue(Attribute.IMAPPort) {
            imapPort.text = "\(port as! Int)"
        }
        imapPort.keyboardType = UIKeyboardType.NumberPad
        imapPort.frame = CGRect.init(x: 0, y: imapServer.frame.height+padding+imapLabel.frame.height+padding, width: 50, height: 30)
        
        let imap = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: imapServer.frame.height+padding+imapLabel.frame.height+padding+imapPort.frame.height))
        imap.addSubview(imapServer)
        imap.addSubview(imapLabel)
        imap.addSubview(imapPort)
        
        let imap1 = OnboardingContentViewController.contentWithTitle(nil, body: "IMAP-Server", videoURL: nil, inputView: imap, buttonText: nil, actionBlock: nil)
        
        let imapAuthLabel = UILabel.init()
        imapAuthLabel.text = "IMAP-Authentifizierung"
        
        imapAuthLabel.textColor = UIColor.whiteColor();
        imapAuthLabel.font = font
        imapAuthLabel.numberOfLines = 0;
        imapAuthLabel.textAlignment = NSTextAlignment.Center;
        imapAuthLabel.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        
        imapAuthentication = UIPickerView.init()
        let imapAuthDataDelegate = PickerDataDelegate.init(rows: Array(authenticationRows.values))
        imapAuthentication.dataSource = imapAuthDataDelegate
        imapAuthentication.frame = CGRect.init(x: 0, y: imapAuthLabel.frame.height+padding, width: 50, height: 50)
        imapAuthentication.tintColor = UIColor.whiteColor()
        let row = UserManager.loadUserValue(Attribute.IMAPAuthType) as! Int
        if Array(authenticationRows.keys).contains(row){
            imapAuthentication.selectRow(row, inComponent: 0, animated: false)
        }
        
        let imapAuth = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: imapServer.frame.height+padding+imapAuthLabel.frame.height+padding+imapPort.frame.height))
        imapAuth.addSubview(imapAuthLabel)
        imapAuth.addSubview(imapAuthentication)
        
        let imap2 = OnboardingContentViewController.contentWithTitle(nil, body: "IMAP-Transferverschlüsselung", videoURL: nil, inputView: imapAuth, buttonText: nil, actionBlock: nil)
        
        
        smtpServer.borderStyle = UITextBorderStyle.RoundedRect
        smtpServer.text = UserManager.loadUserValue(Attribute.SMTPHostname) as? String
        smtpServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        
        let smtpLabel = UILabel.init()
        smtpLabel.text = "SMTP-Port"
        
        smtpLabel.textColor = UIColor.whiteColor();
        smtpLabel.font = font
        smtpLabel.numberOfLines = 0;
        smtpLabel.textAlignment = NSTextAlignment.Center;
        smtpLabel.frame = CGRect.init(x: 0, y: smtpServer.frame.height+padding, width: 50, height: 30)
        smtpPort.borderStyle = UITextBorderStyle.RoundedRect
        smtpPort.text = "0"
        if let port = UserManager.loadUserValue(Attribute.SMTPPort) {
            smtpPort.text = "\(port as! Int)"
        }
        smtpPort.keyboardType = UIKeyboardType.NumberPad
        smtpPort.frame = CGRect.init(x: 0, y: smtpServer.frame.height+padding+smtpLabel.frame.height+padding, width: 50, height: 30)
        
        let smtp = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: smtpServer.frame.height+padding+smtpLabel.frame.height+padding+smtpPort.frame.height))
        smtp.addSubview(smtpServer)
        smtp.addSubview(smtpLabel)
        smtp.addSubview(smtpPort)
        
        let smtp1 = OnboardingContentViewController.contentWithTitle(nil, body: "SMTP-Server", videoURL: nil, inputView: smtp, buttonText: nil, actionBlock: nil)
        
        let last = OnboardingContentViewController.contentWithTitle("Alles richtig?", body: nil, videoURL: nil, inputView: nil, buttonText: "Weiter", actionBlock: callback)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [start, email, user, passwd, imap1, imap2, smtp1, last])
    }
    
    static func checkConfig(fail: () -> (), work: () -> ()) -> Bool {
        smtpCheckDone = false
        imapCheckDone = false
        manualSet = true
        self.work = work
        self.fail = fail
        //AppDelegate.getAppDelegate().mailHandler.checkSMTP(smtpCompletion)
        AppDelegate.getAppDelegate().mailHandler.checkIMAP(imapCompletion)
        /*print("called2")
        print("checks ", imapCheck, smtpCheck)
        print(MCOAuthType(rawValue: UserManager.loadUserValue(Attribute.IMAPAuthType) as! Int))
        print(MCOAuthType.SASLPlain)
        print(MCOAuthType.SASLPlain.rawValue)
        print(MCOConnectionType(rawValue: UserManager.loadUserValue(Attribute.IMAPConnectionType) as! Int))*/
        //print(UserManager.loadUserValue(Attribute.ConnectionType) as! MCOConnectionType)
        return true
    }
    
    static func imapCompletion(error: NSError?) {
        imapCheckDone = true
        imapCheck = error == nil
        if imapCheck {
            AppDelegate.getAppDelegate().mailHandler.checkSMTP(smtpCompletion)
            return
        }
        fail()
    }
    
    static func smtpCompletion(error: NSError?){
        smtpCheckDone = true
        smtpCheck = error == nil
        if smtpCheck {
            work()
            return
        }
        fail()
    }
    
    static func setGuessValues() {
        
        if let mailAddress = mailaddress.text where !manualSet && mailAddress != "" && mailAddress.containsString("@") {
            let guessedUserName = mailAddress.componentsSeparatedByString("@")[0]
            let provider = mailAddress.componentsSeparatedByString("@")[1]
            UserManager.storeUserValue(mailAddress, attribute: Attribute.UserAddr)//Attribute.attributeValues[Attribute.UserAddr] = addr
            UserManager.storeUserValue(guessedUserName, attribute: Attribute.UserName)
            if provider == Provider.FU.rawValue {
                Providers.setValues(Provider.FU)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.Accountname)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.UserName)
            }
            if provider == Provider.ZEDAT.rawValue {
                Providers.setValues(Provider.ZEDAT)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.Accountname)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.UserName)
            }
            if provider == Provider.ENZEVALOS.rawValue {
                Providers.setValues(Provider.ENZEVALOS)
                UserManager.storeUserValue(guessedUserName, attribute: Attribute.Accountname)
                UserManager.storeUserValue(guessedUserName, attribute: Attribute.UserName)
            }
        }
        if let pw = password.text where pw != "" {
            UserManager.storeUserValue(pw, attribute: Attribute.UserPW)
        }
        if manualSet {
            UserManager.storeUserValue(imapServer.text, attribute: Attribute.IMAPHostname)
            UserManager.storeUserValue(Int(imapPort.text!), attribute: Attribute.IMAPPort)
            UserManager.storeUserValue(smtpServer.text, attribute: Attribute.SMTPHostname)
            UserManager.storeUserValue(Int(smtpPort.text!), attribute: Attribute.SMTPPort)
            UserManager.storeUserValue(mailaddress.text, attribute: Attribute.UserAddr)
            UserManager.storeUserValue(password.text!, attribute: Attribute.UserPW)
            UserManager.storeUserValue(username.text!, attribute: Attribute.UserName)
            UserManager.storeUserValue(username.text!, attribute: Attribute.Accountname)
        }
        
    }
    
    static func keyHandling() {
        for encType in iterateEnum(EncryptionType) {
            let encryption = EnzevalosEncryptionHandler.getEncryption(encType)
            if let enc = encryption {
                enc.removeAllKeys()
            }
        }
        EnzevalosEncryptionHandler.getEncryption(.PGP)?.printAllKeyIDs()
            //---------------------------------------
            //Import private Key BEGIN
            
            var path = NSBundle.mainBundle().pathForResource("alice2005-private", ofType: "gpg")        //<---- Schlüsseldatei
            if UserManager.loadUserValue(Attribute.UserAddr)!.containsString("@") && UserManager.loadUserValue(Attribute.UserAddr)!.componentsSeparatedByString("@")[1] == Provider.ENZEVALOS.rawValue {
                path = NSBundle.mainBundle().pathForResource("quizer1-private", ofType: "asc")
            }
            var pgp = ObjectivePGP.init()
            pgp.importKeysFromFile(path!, allowDuplicates: false)
            var enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
            do {
                let data = try pgp.keys[0].export()
                enc?.addKey(data, forMailAddresses: [])
            }
            catch _ {}
            
            //Import private key END
            //---------------------------------------
            //---------------------------------------
            //Import public Key BEGIN
            
            path = NSBundle.mainBundle().pathForResource("JakobBode", ofType: "asc")               //<---- Schlüsseldatei
            pgp = ObjectivePGP.init()
            pgp.importKeysFromFile(path!, allowDuplicates: false)
            enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
            do {
                let data = try pgp.keys[0].export()
                enc?.addKey(data, forMailAddresses: ["jakob.bode@fu-berlin.de"])                           //<---- Emailadresse
            }
            catch _ {}
            
            //Import public key END
            //---------------------------------------
            //---------------------------------------
            //Import public Key BEGIN
            
            path = NSBundle.mainBundle().pathForResource("alice2005-public", ofType: "gpg")               //<---- Schlüsseldatei
            pgp = ObjectivePGP.init()
            pgp.importKeysFromFile(path!, allowDuplicates: false)
            enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
            do {
                let data = try pgp.keys[0].export()
                enc?.addKey(data, forMailAddresses: ["alice2005@web.de"])                           //<---- Emailadresse
            }
            catch _ {}
            
            //Import public key END
            //---------------------------------------
            //---------------------------------------
            //Import public Key BEGIN
            
            path = NSBundle.mainBundle().pathForResource("quizer1-public", ofType: "asc")               //<---- Schlüsseldatei
            pgp = ObjectivePGP.init()
            pgp.importKeysFromFile(path!, allowDuplicates: false)
            enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
            do {
                let data = try pgp.keys[0].export()
                enc?.addKey(data, forMailAddresses: ["quizer1@enzevalos.de"])                           //<---- Emailadresse
            }
            catch _ {}
            
            //Import public key END
            //---------------------------------------
    }
    
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
        var i = 0
        return anyGenerator {
            let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
            return next.hashValue == i++ ? next : nil
        }
    }
}

class PickerDataDelegate : NSObject, UIPickerViewDataSource {
    var rows = ["Keine", "Normal, Password", "Login"]
    
    init(rows : [String]){
        super.init()
        self.rows = rows
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return rows.count
    }
    
}
extension PickerDataDelegate : UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component < 0 || component >= rows.count {
            return nil
        }
        return rows[component]
    }
}
