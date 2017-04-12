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
    static var imapAuthDataDelegate = PickerDataDelegate.init(rows: ["a", "b", "c"])
    static var imapTransportEncryption = UIPickerView.init()
    static var imapTransDataDelegate = PickerDataDelegate.init(rows: ["a", "b", "c"])
    static var smtpAuthentication = UIPickerView.init()
    static var smtpAuthDataDelegate = PickerDataDelegate.init(rows: ["a", "b", "c"])
    static var smtpTransportEncryption = UIPickerView.init()
    static var smtpTransDataDelegate = PickerDataDelegate.init(rows: ["a", "b", "c"])
    static var background = UIImage.init()
    static var smtpCheck = false
    static var smtpCheckDone = false
    static var imapCheck = false
    static var imapCheckDone = false
    static var manualSet = false
    
    static let font = UIFont.init(name: "Helvetica-Light", size: 28)
    static let padding : CGFloat = 30
    
    static var fail : () -> () = {Void in}
    static var work : () -> () = {Void in}

    static var authenticationRows : [Int : String] = [MCOAuthType.saslLogin.rawValue : "Login", MCOAuthType.saslPlain.rawValue : NSLocalizedString("NormalPassword", comment: ""), MCOAuthType.SASLSRP.rawValue : "SRP", MCOAuthType.SASLCRAMMD5.rawValue : "CRAMMD5", MCOAuthType.SASLDIGESTMD5.rawValue : "DIGESTMD5", MCOAuthType.SASLNTLM.rawValue : "NTLM", MCOAuthType.SASLGSSAPI.rawValue : "GSSAPI", MCOAuthType.saslKerberosV4.rawValue : "KerberosV4"]
    static var transportRows : [Int : String] = [MCOConnectionType.clear.rawValue : NSLocalizedString("Plaintext", comment: ""), MCOConnectionType.startTLS.rawValue : "StartTLS", MCOConnectionType.TLS.rawValue : "TLS"]
    
    static func onboarding(_ callback: @escaping ()->()) -> UIViewController {
        
        //Background
        
        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, false, 2) //try 200 here
        
        let context = UIGraphicsGetCurrentContext()
        
        //
        // Clip context to a circle
        //
        let path = CGPath(ellipseIn: myBounds, transform: nil);
        context!.addPath(path);
        context!.clip();
        
        
        //
        // Fill background of context
        //
        context!.setFillColor(UIColor.init(red: 0.1, green: 1.0, blue: 0.3, alpha: 0.0).cgColor)
        context!.fill(CGRect(x: 0, y: 0, width: myBounds.size.width, height: myBounds.size.height));
        
        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        background = snapshot!
        
        //Content
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("Hello", comment: "Welcome"), body: NSLocalizedString("InterestedInSecureMail", comment: "commendation to user for using secure mail"), image: nil, buttonText: nil, action: nil)
        mailaddress = UITextField.init()
        //text.textColor = UIColor.whiteColor()
        //text.tintColor = UIColor.whiteColor()
        mailaddress.borderStyle = UITextBorderStyle.roundedRect
        mailaddress.keyboardType = UIKeyboardType.emailAddress
        mailaddress.autocorrectionType = UITextAutocorrectionType.no
        mailaddress.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        mailaddress.placeholder = NSLocalizedString("Address", comment: "")
        let page2 = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertMailAddress", comment: ""), videoURL: nil, inputView: mailaddress, buttonText: nil, actionBlock: nil)
        
        password = UITextField.init()
        //text.textColor = UIColor.whiteColor()
        //text.tintColor = UIColor.whiteColor()
        password.borderStyle = UITextBorderStyle.roundedRect
        password.isSecureTextEntry = true
        password.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        password.placeholder = NSLocalizedString("Password", comment: "")
        let page3 = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertPassword", comment: ""), videoURL: nil, inputView: password, buttonText: nil, actionBlock: nil)
        let page4 = OnboardingContentViewController.content(withTitle: NSLocalizedString("EverythingCorrect", comment: ""), body: nil, videoURL: nil, inputView: nil, buttonText: NSLocalizedString("next", comment: ""), actionBlock: callback)
        
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1, page2, page3, page4])
    }
    
    static func checkConfigView() -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("ConnectingToMailServer", comment: ""), body: nil, videoURL: nil, inputView: view, buttonText: nil, actionBlock: nil)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
    }
    
    static func keyHandlingView() -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("CreateAndManageKeys", comment: ""), body: nil, videoURL: nil, inputView: view, buttonText: nil, actionBlock: nil)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
    }
    
    static func detailOnboarding(_ callback: @escaping ()->()) -> UIViewController {
        
        let start = OnboardingContentViewController.content(withTitle: NSLocalizedString("WhatAShame", comment: ""), body: NSLocalizedString("CouldNotConnect", comment: ""), videoURL: nil, inputView: nil, buttonText: nil, actionBlock: nil)
        
        
        let email = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertMailAddress", comment: ""), videoURL: nil, inputView: mailaddress, buttonText: nil, actionBlock: nil)
        
        username = UITextField.init()
        //text.textColor = UIColor.whiteColor()
        //text.tintColor = UIColor.whiteColor()
        username.borderStyle = UITextBorderStyle.roundedRect
        username.keyboardType = UIKeyboardType.emailAddress
        username.autocorrectionType = UITextAutocorrectionType.no
        username.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        username.placeholder = NSLocalizedString("Username", comment: "")
        username.text = UserManager.loadUserValue(Attribute.userName) as? String
        
        let user = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertUsername", comment: ""), videoURL: nil, inputView: username, buttonText: nil, actionBlock: nil)
        
        let passwd = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertPassword", comment: ""), videoURL: nil, inputView: password, buttonText: nil, actionBlock: nil)
        
        imapServer.borderStyle = UITextBorderStyle.roundedRect
        imapServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        imapServer.text = UserManager.loadUserValue(Attribute.imapHostname) as? String
        
        let imapLabel = UILabel.init()
        imapLabel.text = "IMAP-Port"
        
        imapLabel.textColor = UIColor.white;
        imapLabel.font = font
        imapLabel.numberOfLines = 0;
        imapLabel.textAlignment = NSTextAlignment.center;
        imapLabel.frame = CGRect.init(x: 0, y: imapServer.frame.height+padding, width: 50, height: 30)
        imapPort.borderStyle = UITextBorderStyle.roundedRect
        imapPort.text = "0"
        if let port = UserManager.loadUserValue(Attribute.imapPort) {
            imapPort.text = "\(port as! Int)"
        }
        imapPort.keyboardType = UIKeyboardType.numberPad
        imapPort.frame = CGRect.init(x: 0, y: imapServer.frame.height+padding+imapLabel.frame.height+padding, width: 50, height: 30)
        
        let imap = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: imapServer.frame.height+padding+imapLabel.frame.height+padding+imapPort.frame.height))
        imap.addSubview(imapServer)
        imap.addSubview(imapLabel)
        imap.addSubview(imapPort)
        
        let imap1 = OnboardingContentViewController.content(withTitle: nil, body: "IMAP-Server", videoURL: nil, inputView: imap, buttonText: nil, actionBlock: nil)
        
        imapTransportEncryption = UIPickerView()
        imapTransDataDelegate = PickerDataDelegate.init(rows: Array(transportRows.values))
        imapTransportEncryption.dataSource = imapTransDataDelegate
        imapTransportEncryption.delegate = imapTransDataDelegate
        imapTransportEncryption.frame = CGRect.init(x: 0, y: 0, width: 50, height: 100)
        imapTransportEncryption.reloadAllComponents()
        //imapAuthentication.backgroundColor = UIColor.whiteColor()
        var row = UserManager.loadUserValue(Attribute.imapConnectionType) as! Int
        imapTransDataDelegate.pickedValue = transportRows[row]!
        row = imapTransDataDelegate.rows.index(of: transportRows[row]!)!
        //if Array(transportRows.keys).contains(row){
            imapTransportEncryption.selectRow(row, inComponent: 0, animated: false)
        //}
        
        let imapAuthLabel = UILabel.init()
        imapAuthLabel.text = "IMAP-"+NSLocalizedString("Authentification", comment: "")
        
        imapAuthLabel.textColor = UIColor.white;
        imapAuthLabel.font = font
        imapAuthLabel.numberOfLines = 0;
        imapAuthLabel.textAlignment = NSTextAlignment.center;
        imapAuthLabel.frame = CGRect.init(x: 0, y: imapTransportEncryption.frame.height, width: 50, height: 30)
        
        imapAuthentication = UIPickerView()
        imapAuthDataDelegate = PickerDataDelegate.init(rows: Array(authenticationRows.values))
        imapAuthentication.dataSource = imapAuthDataDelegate
        imapAuthentication.delegate = imapAuthDataDelegate
        imapAuthentication.frame = CGRect.init(x: 0, y: imapTransportEncryption.frame.height+imapAuthLabel.frame.height, width: 50, height: 100)
        imapAuthentication.reloadAllComponents()
        imapAuthentication.reloadInputViews()
        imapAuthentication.tintColor = UIColor.white
        //imapAuthentication.backgroundColor = UIColor.whiteColor()
        row = UserManager.loadUserValue(Attribute.imapAuthType) as! Int
        imapAuthDataDelegate.pickedValue = authenticationRows[row]!
        row = Array(authenticationRows.values).index(of: authenticationRows[row]!)!
        //if Array(authenticationRows.keys).contains(row){
            imapAuthentication.selectRow(row, inComponent: 0, animated: false)
        //}
        
        let imapAuth = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: imapTransportEncryption.frame.height+padding+imapAuthLabel.frame.height+imapAuthentication.frame.height))
        imapAuth.addSubview(imapTransportEncryption)
        imapAuth.addSubview(imapAuthLabel)
        imapAuth.addSubview(imapAuthentication)
        let boolPointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        boolPointer[0] = false
        let imap2 = OnboardingContentViewController.content(withTitle: nil, body: "IMAP-"+NSLocalizedString("Transportencryption", comment: ""), videoURL: nil, inputView: imapAuth, buttonText: nil, actionBlock: nil, withPadding: boolPointer)
        
        
        smtpServer.borderStyle = UITextBorderStyle.roundedRect
        smtpServer.text = UserManager.loadUserValue(Attribute.smtpHostname) as? String
        smtpServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        
        let smtpLabel = UILabel.init()
        smtpLabel.text = "SMTP-Port"
        
        smtpLabel.textColor = UIColor.white;
        smtpLabel.font = font
        smtpLabel.numberOfLines = 0;
        smtpLabel.textAlignment = NSTextAlignment.center;
        smtpLabel.frame = CGRect.init(x: 0, y: smtpServer.frame.height+padding, width: 50, height: 30)
        smtpPort.borderStyle = UITextBorderStyle.roundedRect
        smtpPort.text = "0"
        if let port = UserManager.loadUserValue(Attribute.smtpPort) {
            smtpPort.text = "\(port as! Int)"
        }
        smtpPort.keyboardType = UIKeyboardType.numberPad
        smtpPort.frame = CGRect.init(x: 0, y: smtpServer.frame.height+padding+smtpLabel.frame.height+padding, width: 50, height: 30)
        
        let smtp = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: smtpServer.frame.height+padding+smtpLabel.frame.height+padding+smtpPort.frame.height))
        smtp.addSubview(smtpServer)
        smtp.addSubview(smtpLabel)
        smtp.addSubview(smtpPort)
        
        let smtp1 = OnboardingContentViewController.content(withTitle: nil, body: "SMTP-Server", videoURL: nil, inputView: smtp, buttonText: nil, actionBlock: nil)
        
        smtpTransportEncryption = UIPickerView()
        smtpTransDataDelegate = PickerDataDelegate.init(rows: Array(transportRows.values))
        smtpTransportEncryption.dataSource = smtpTransDataDelegate
        smtpTransportEncryption.delegate = smtpTransDataDelegate
        smtpTransportEncryption.frame = CGRect.init(x: 0, y: 0, width: 50, height: 100)
        smtpTransportEncryption.reloadAllComponents()
        //smtpAuthentication.backgroundColor = UIColor.whiteColor()
        row = UserManager.loadUserValue(Attribute.smtpConnectionType) as! Int
        smtpTransDataDelegate.pickedValue = transportRows[row]!
        row = smtpTransDataDelegate.rows.index(of: transportRows[row]!)!
        //if Array(transportRows.keys).contains(row){
        smtpTransportEncryption.selectRow(row, inComponent: 0, animated: false)
        //}
        
        let smtpAuthLabel = UILabel.init()
        smtpAuthLabel.text = "SMTP-"+NSLocalizedString("Authentification", comment: "")
        
        smtpAuthLabel.textColor = UIColor.white;
        smtpAuthLabel.font = font
        smtpAuthLabel.numberOfLines = 0;
        smtpAuthLabel.textAlignment = NSTextAlignment.center;
        smtpAuthLabel.frame = CGRect.init(x: 0, y: smtpTransportEncryption.frame.height, width: 50, height: 30)
        
        smtpAuthentication = UIPickerView()
        smtpAuthDataDelegate = PickerDataDelegate.init(rows: Array(authenticationRows.values))
        smtpAuthentication.dataSource = smtpAuthDataDelegate
        smtpAuthentication.delegate = smtpAuthDataDelegate
        smtpAuthentication.frame = CGRect.init(x: 0, y: smtpTransportEncryption.frame.height+smtpAuthLabel.frame.height, width: 50, height: 100)
        smtpAuthentication.reloadAllComponents()
        smtpAuthentication.reloadInputViews()
        smtpAuthentication.tintColor = UIColor.white
        //smtpAuthentication.backgroundColor = UIColor.whiteColor()
        row = UserManager.loadUserValue(Attribute.smtpAuthType) as! Int
        smtpAuthDataDelegate.pickedValue = authenticationRows[row]!
        row = Array(authenticationRows.values).index(of: authenticationRows[row]!)!
        //if Array(authenticationRows.keys).contains(row){
        smtpAuthentication.selectRow(row, inComponent: 0, animated: false)
        //}
        
        let smtpAuth = UIView.init(frame: CGRect.init(x:0, y:0, width: 50, height: smtpTransportEncryption.frame.height+padding+smtpAuthLabel.frame.height+smtpAuthentication.frame.height))
        smtpAuth.addSubview(smtpTransportEncryption)
        smtpAuth.addSubview(smtpAuthLabel)
        smtpAuth.addSubview(smtpAuthentication)
        boolPointer[0] = false
        let smtp2 = OnboardingContentViewController.content(withTitle: nil, body: "SMTP-"+NSLocalizedString("Transportencryption", comment: ""), videoURL: nil, inputView: smtpAuth, buttonText: nil, actionBlock: nil, withPadding: boolPointer)

        
        let last = OnboardingContentViewController.content(withTitle: NSLocalizedString("EverythingCorrect", comment: ""), body: nil, videoURL: nil, inputView: nil, buttonText: NSLocalizedString("next", comment: ""), actionBlock: callback)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [start, email, user, passwd, imap1, imap2, smtp1, smtp2, last])
    }
    
    static func contactView(_ callback: @escaping () -> ()) -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("AccessContacts", comment: ""), body: NSLocalizedString("AccessContactsDescription", comment: "Description, why we need access"), videoURL: nil, inputView: nil, buttonText: NSLocalizedString("next", comment: ""), actionBlock: callback)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
    }
    
    static func checkContact(_ callback : @escaping (Bool) -> ()){
        AppDelegate.getAppDelegate().requestForAccess(callback)
    }
    
    static func checkConfig(_ fail: @escaping () -> (), work: @escaping () -> ()) -> Bool {
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
    
    static func imapCompletion(_ error: Error?) { //FIXME: vorher NSError? Mit Error? immer noch gültig?
        imapCheckDone = true
        imapCheck = error == nil
        if imapCheck {
            AppDelegate.getAppDelegate().mailHandler.checkSMTP(smtpCompletion)
            return
        }
        fail()
    }
    
    static func smtpCompletion(_ error: Error?){ //FIXME: vorher NSError? Mit Error? immer noch gültig?
        smtpCheckDone = true
        smtpCheck = error == nil
        if smtpCheck {
            work()
            return
        }
        fail()
    }
    
    static func setGuessValues() {
        
        if let mailAddress = mailaddress.text, !manualSet && mailAddress != "" && mailAddress.contains("@") {
            let guessedUserName = mailAddress.components(separatedBy: "@")[0]
            let provider = mailAddress.components(separatedBy: "@")[1]
            UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userAddr)//Attribute.attributeValues[Attribute.UserAddr] = addr
            UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.userName)
            if provider == Provider.FU.rawValue {
                Providers.setValues(Provider.FU)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.accountname)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.userName)
            }
            if provider == Provider.ZEDAT.rawValue {
                Providers.setValues(Provider.ZEDAT)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.accountname)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.userName)
            }
            if provider == Provider.ENZEVALOS.rawValue {
                Providers.setValues(Provider.ENZEVALOS)
                UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.accountname)
                UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.userName)
            }
            if provider == Provider.WEB.rawValue {
                Providers.setValues(Provider.WEB)
            }
        }
        if let pw = password.text, pw != "" {
            UserManager.storeUserValue(pw as AnyObject?, attribute: Attribute.userPW)
        }
        if manualSet {
            UserManager.storeUserValue(imapServer.text as AnyObject?, attribute: Attribute.imapHostname)
            UserManager.storeUserValue(Int(imapPort.text!) as AnyObject?, attribute: Attribute.imapPort)
            UserManager.storeUserValue(smtpServer.text as AnyObject?, attribute: Attribute.smtpHostname)
            UserManager.storeUserValue(Int(smtpPort.text!) as AnyObject?, attribute: Attribute.smtpPort)
            UserManager.storeUserValue(mailaddress.text as AnyObject?, attribute: Attribute.userAddr)
            UserManager.storeUserValue(password.text! as AnyObject?, attribute: Attribute.userPW)
            UserManager.storeUserValue(username.text! as AnyObject?, attribute: Attribute.userName)
            UserManager.storeUserValue(username.text! as AnyObject?, attribute: Attribute.accountname)
            UserManager.storeUserValue(keyForValue(transportRows, value: imapTransDataDelegate.pickedValue)[0] as AnyObject?, attribute: Attribute.imapConnectionType)
            UserManager.storeUserValue(keyForValue(authenticationRows, value: imapAuthDataDelegate.pickedValue)[0] as AnyObject?, attribute: Attribute.imapAuthType)
            UserManager.storeUserValue(keyForValue(transportRows, value: smtpTransDataDelegate.pickedValue)[0] as AnyObject?, attribute: Attribute.smtpConnectionType)
            UserManager.storeUserValue(keyForValue(authenticationRows, value: smtpAuthDataDelegate.pickedValue)[0] as AnyObject?, attribute: Attribute.smtpAuthType)
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
            
            var path = Bundle.main.path(forResource: "alice2005-private", ofType: "gpg")        //<---- Schlüsseldatei
            if UserManager.loadUserValue(Attribute.userAddr)!.contains("@") && UserManager.loadUserValue(Attribute.userAddr)!.components(separatedBy: "@")[1] == Provider.ENZEVALOS.rawValue {
                path = Bundle.main.path(forResource: "quizer1-private", ofType: "asc")
            }
            var pgp = ObjectivePGP.init()
            pgp.importKeys(fromFile: path!, allowDuplicates: false)
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
            
            path = Bundle.main.path(forResource: "JakobBode", ofType: "asc")               //<---- Schlüsseldatei
            pgp = ObjectivePGP.init()
            pgp.importKeys(fromFile: path!, allowDuplicates: false)
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
            
            path = Bundle.main.path(forResource: "alice2005-public", ofType: "gpg")               //<---- Schlüsseldatei
            pgp = ObjectivePGP.init()
            pgp.importKeys(fromFile: path!, allowDuplicates: false)
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
            
            path = Bundle.main.path(forResource: "quizer1-public", ofType: "asc")               //<---- Schlüsseldatei
            pgp = ObjectivePGP.init()
            pgp.importKeys(fromFile: path!, allowDuplicates: false)
            enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
            do {
                let data = try pgp.keys[0].export()
                enc?.addKey(data, forMailAddresses: ["quizer1@enzevalos.de"])                           //<---- Emailadresse
            }
            catch _ {}
            
            //Import public key END
            //---------------------------------------
    }
    
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) { UnsafeRawPointer($0).load(as: T.self) }
            i = i + 1
            return next.hashValue == (i-1) ? next : nil
        }
    }
    
    
    //Inspired by http://stackoverflow.com/questions/32692450/swift-dictionary-get-key-for-values
    static func keyForValue(_ dict : [Int : String], value : String) -> [Int]{
        let keys = dict.filter {
            return $0.1 == value
            }.map {
                return $0.0
        }
        return keys
    }
}

class PickerDataDelegate : NSObject, UIPickerViewDataSource {
    var rows = ["Keine", "Normal, Password", "Login"]
    var pickedValue = ""
    
    init(rows : [String]){
        super.init()
        self.rows = rows
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return rows.count
    }
    
    
    
}
extension PickerDataDelegate : UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return rows[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel(frame: CGRect.init(x: 0, y: 0, width: 0/*pickerView.frame.width*/, height: 30))
        label.text = rows[row]
        label.textAlignment = NSTextAlignment.center
        label.font = Onboarding.font?.withSize((Onboarding.font?.pointSize)!-CGFloat(5))
        //label.backgroundColor = UIColor.greenColor()
        label.textColor = UIColor.white
        return label
    }
    
    /*func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if row < 0 || row >= rows.count {
            return nil
        }
        return NSAttributedString(string: rows[row])
    }*/
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickedValue = rows[row]
    }
}
