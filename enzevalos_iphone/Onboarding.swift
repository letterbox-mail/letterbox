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
    static var password = UITextField.init()
    static var imapServer = UITextField.init()
    static var smtpServer = UITextField.init()
    static var imapPort = UITextField.init()
    static var smtpPort = UITextField.init()
    static var authentication = UIPickerView.init()
    static var transportEncryption = UIPickerView.init()
    static var background = UIImage.init()
    static var smtpCheck = false
    static var smtpCheckDone = false
    static var imapCheck = false
    static var imapCheckDone = false
    static var manualSet = false
    
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
        let page1 = OnboardingContentViewController.contentWithTitle("Verbinde zum Mailserver", body: nil, videoURL: nil, inputView: activity, buttonText: nil, actionBlock: nil)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
    }
    
    static func detailOnboarding(callback: dispatch_block_t) -> UIViewController {
        let page1 = OnboardingContentViewController.contentWithTitle("Schade!", body: "Die Verbindung zum Server konnte nicht hergestellt werden. Bitte überprüfe die folgenden Angaben und passe sie ggf. an.", videoURL: nil, inputView: nil, buttonText: nil, actionBlock: nil)
        
        imapServer.borderStyle = UITextBorderStyle.RoundedRect
        imapServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        imapServer.text = UserManager.loadUserValue(Attribute.IMAPHostname) as? String
        let page2 = OnboardingContentViewController.contentWithTitle(nil, body: "IMAP-Server", videoURL: nil, inputView: imapServer, buttonText: nil, actionBlock: nil)
        
        imapPort.borderStyle = UITextBorderStyle.RoundedRect
        imapPort.text = "0"
        if let port = UserManager.loadUserValue(Attribute.IMAPPort) {
            imapPort.text = "\(port as! Int)"
        }
        imapPort.keyboardType = UIKeyboardType.NumberPad
        imapPort.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        let page3 = OnboardingContentViewController.contentWithTitle(nil, body: "IMAP-Port", videoURL: nil, inputView: imapPort, buttonText: nil, actionBlock: nil)
        
        smtpServer.borderStyle = UITextBorderStyle.RoundedRect
        smtpServer.text = UserManager.loadUserValue(Attribute.SMTPHostname) as? String
        smtpServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        let page4 = OnboardingContentViewController.contentWithTitle(nil, body: "SMTP-Server", videoURL: nil, inputView: smtpServer, buttonText: nil, actionBlock: nil)
        
        smtpPort.borderStyle = UITextBorderStyle.RoundedRect
        smtpPort.text = "0"
        if let port = UserManager.loadUserValue(Attribute.SMTPPort) {
            smtpPort.text = "\(port as! Int)"
        }
        smtpPort.keyboardType = UIKeyboardType.NumberPad
        smtpPort.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        let page5 = OnboardingContentViewController.contentWithTitle(nil, body: "SMTP-Port", videoURL: nil, inputView: smtpPort, buttonText: nil, actionBlock: nil)
        
        let last = OnboardingContentViewController.contentWithTitle("Alles richtig?", body: nil, videoURL: nil, inputView: nil, buttonText: "Weiter", actionBlock: callback)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1, page2, page3, page4, page5, last])
    }
    
    static func checkConfig() -> Bool {
        return false
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
        if let pw = password.text where !manualSet && pw != "" {
            UserManager.storeUserValue(pw, attribute: Attribute.UserPW)
        }
        smtpCheckDone = false
        imapCheckDone = false
        manualSet = true
        /*AppDelegate.getAppDelegate().mailHandler.checkSMTP(SMTPCompletion)
         AppDelegate.getAppDelegate().mailHandler.checkIMAP(IMAPCompletion)
         while (!imapCheckDone || !smtpCheckDone) {
         
         }*/
        print("checks ", imapCheck, smtpCheck)
    }
}
