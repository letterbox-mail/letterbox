//
//  Onboarding.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 29.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Onboard

class Onboarding: NSObject {

    override init() {
        super.init()
    }

    static var textDelegate = TextFieldDelegate.init()
    static let defaultColor = UIColor.darkGray//UIColor.init(red: 0.6, green: 0.6, blue: 1, alpha: 1)
    static let textColor = UIColor.white
    static var mailaddress = UITextField.init()
    static var username = UITextField.init()
    static var password = UITextField.init()
    static var credentials: UIView? = nil
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
    static var manualSet = false

    static let font = UIFont.init(name: "Helvetica-Light", size: 28)
    static let padding: CGFloat = 30

    static var doWhenDone: () -> () = { Void in }
    static var fail: () -> () = { Void in }
    static var work: () -> () = { Void in }

    static var credentialFails = 0

    static var authenticationRows: [Int: String] = [MCOAuthType.saslLogin.rawValue: "Login", MCOAuthType.saslPlain.rawValue: NSLocalizedString("NormalPassword", comment: ""), MCOAuthType.SASLSRP.rawValue: "SRP", MCOAuthType.SASLCRAMMD5.rawValue: "CRAMMD5", MCOAuthType.SASLDIGESTMD5.rawValue: "DIGESTMD5", MCOAuthType.SASLNTLM.rawValue: "NTLM", MCOAuthType.SASLGSSAPI.rawValue: "GSSAPI", MCOAuthType.saslKerberosV4.rawValue: "KerberosV4", 0: "None"]
    static var transportRows: [Int: String] = [MCOConnectionType.clear.rawValue: NSLocalizedString("Plaintext", comment: ""), MCOConnectionType.startTLS.rawValue: "StartTLS", MCOConnectionType.TLS.rawValue: "TLS"]

    static func onboarding(_ callback: @escaping () -> ()) -> UIViewController {

        doWhenDone = callback

        //Background

        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, true, 0) //try 200 here
        var context = UIGraphicsGetCurrentContext()
        context!.setFillColor(UIColor.init(red: 1, green: 1, blue: 1, alpha: 1).cgColor)
        context!.fill(CGRect(x: 0, y: 0, width: myBounds.size.width, height: myBounds.size.height));
        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, true, 0)
        context = UIGraphicsGetCurrentContext()
        context!.setFillColor(ThemeManager.uncryptedMessageColor().cgColor)
        context!.fill(CGRect(x: 0, y: 0, width: myBounds.size.width, height: myBounds.size.height));
        UIGraphicsEndImageContext();

        background = snapshot!

        //Introduction
        let intro0 = OnboardingContentViewController.content(withTitle: NSLocalizedString("Welcome", comment: "Welcome"), body: NSLocalizedString("ReadFollowingPages", comment: ""), image: nil, buttonText: nil, action: nil)

        let intro1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("Letter", comment: ""), body: NSLocalizedString("LetterDescription", comment: "describe the letter"), image: nil, buttonText: nil, action: nil)

        intro1.iconHeight = 70
        intro1.iconWidth = 100
        if kDefaultBodyFontSize < 28 {
            intro1.iconHeight = 56
            intro1.iconWidth = 80
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: intro1.iconWidth, height: intro1.iconHeight), false, 0)
        IconsStyleKit.drawLetter(frame: CGRect(x: 0, y: 0, width: intro1.iconWidth, height: intro1.iconHeight), fillBackground: true)
        intro1.iconImageView.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        intro1.bodyLabel.textAlignment = NSTextAlignment.left

        let intro2 = OnboardingContentViewController.content(withTitle: NSLocalizedString("Postcard", comment: ""), body: NSLocalizedString("PostcardDescription", comment: "describe the postcard"), image: IconsStyleKit.imageOfPostcardBG, buttonText: nil, action: nil)

        intro2.iconHeight = 70
        intro2.iconWidth = 100
        if kDefaultBodyFontSize < 28 {
            intro2.iconHeight = 56
            intro2.iconWidth = 80
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: intro2.iconWidth, height: intro2.iconHeight), false, 0)
        IconsStyleKit.drawPostcard(frame: CGRect(x: 0, y: 0, width: intro2.iconWidth, height: intro2.iconHeight), fillBackground: true)
        intro2.iconImageView.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        intro2.bodyLabel.textAlignment = NSTextAlignment.left

        let path = Bundle.main.path(forResource: "videoOnboarding2", ofType: "m4v")
        let url = URL.init(fileURLWithPath: path!)

        let videoView = UIView.init(frame: CGRect.init(x: 40, y: (AppDelegate.getAppDelegate().window?.frame.height)!*0.5, width: (AppDelegate.getAppDelegate().window?.frame.width)! - 80, height: 1.779*((AppDelegate.getAppDelegate().window?.frame.width)! - 80)))
        
        let intro3 = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("GetHelp", comment: ""), videoURL: url, inputView: videoView, buttonText: nil, actionBlock: nil)

        //Content
        if credentials == nil {
            mailaddress = UITextField.init()
            mailaddress.textColor = textColor
            mailaddress.attributedPlaceholder = NSAttributedString.init(string: NSLocalizedString("Address", comment: ""), attributes: [NSForegroundColorAttributeName: textColor])
            mailaddress.tintColor = textColor
            mailaddress.borderStyle = UITextBorderStyle.none
            mailaddress.keyboardType = UIKeyboardType.emailAddress
            mailaddress.returnKeyType = UIReturnKeyType.next
            mailaddress.autocorrectionType = UITextAutocorrectionType.no
            mailaddress.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
            mailaddress.isUserInteractionEnabled = true
            mailaddress.delegate = textDelegate

            let mailaddressUnderline = UIView.init(frame: CGRect.init(x: 0, y: mailaddress.frame.maxY, width: mailaddress.frame.width, height: 0.5))
            mailaddressUnderline.backgroundColor = textColor

            password = UITextField.init()
            password.textColor = textColor
            password.tintColor = textColor
            password.borderStyle = UITextBorderStyle.none
            password.isSecureTextEntry = true
            password.returnKeyType = UIReturnKeyType.continue
            password.frame = CGRect.init(x: 0, y: mailaddress.frame.height + padding + mailaddressUnderline.frame.height, width: 50, height: 30)
            password.attributedPlaceholder = NSAttributedString.init(string: NSLocalizedString("Password", comment: ""), attributes: [NSForegroundColorAttributeName: textColor])
            password.delegate = textDelegate

            let passwordUnderline = UIView.init(frame: CGRect.init(x: 0, y: mailaddress.frame.height + padding + mailaddressUnderline.frame.height + password.frame.height, width: password.frame.width, height: 0.5))
            passwordUnderline.backgroundColor = textColor

            let keyboardToolbar = UIToolbar()
            keyboardToolbar.sizeToFit()
            keyboardToolbar.barTintColor = defaultColor
            keyboardToolbar.backgroundColor = defaultColor
            let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissKeyboard))
            keyboardToolbar.items = [flexBarButton, doneBarButton]
            mailaddress.inputAccessoryView = keyboardToolbar
            password.inputAccessoryView = keyboardToolbar

            credentials = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: mailaddress.frame.height + mailaddressUnderline.frame.height + padding + password.frame.height + passwordUnderline.frame.height))
            credentials?.addSubview(mailaddress)
            credentials?.addSubview(mailaddressUnderline)
            credentials?.addSubview(password)
            credentials?.addSubview(passwordUnderline)
        }

        var bodyText = NSLocalizedString("InsertMailAddressAndPassword", comment: "")
        if self.credentialFails > 0 {
            bodyText = NSLocalizedString("WrongMailAddressOrPassword", comment: "")
        }
        let page3 = OnboardingContentViewController.content(withTitle: nil, body: bodyText, videoURL: nil, inputView: credentials, buttonText: NSLocalizedString("next", comment: ""), actionBlock: callback)
        page3.topPadding = 0
        if self.credentialFails > 0 {
            page3.bodyLabel.textColor = UIColor.orange
        }

        let vc = Onboard.OnboardingViewController(backgroundImage: background, contents: [intro0, intro1, intro2, intro3, page3])
        vc?.view.backgroundColor = defaultColor
        vc?.shouldFadeTransitions = true

        let duration = 0.5

        intro2.viewWillAppearBlock = {
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                vc?.view.backgroundColor = ThemeManager.uncryptedMessageColor()
                vc?.view.setNeedsDisplay()
            })
        }
        intro2.viewWillDisappearBlock = {
            UIView.animate(withDuration: duration, delay: 0.05, options: UIViewAnimationOptions.curveEaseIn, animations: {
                if (vc?.view.backgroundColor != ThemeManager.encryptedMessageColor()) {
                    vc?.view.backgroundColor = defaultColor
                    vc?.view.setNeedsDisplay()
                }
            })
        }
        intro1.viewWillAppearBlock = {
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { vc?.view.backgroundColor = ThemeManager.encryptedMessageColor(); vc?.view.setNeedsDisplay() })
        }
        intro1.viewWillDisappearBlock = {
            UIView.animate(withDuration: duration, delay: 0.05, options: UIViewAnimationOptions.curveEaseIn, animations: {
                if (vc?.view.backgroundColor != ThemeManager.uncryptedMessageColor()) {
                    vc?.view.backgroundColor = defaultColor
                    vc?.view.setNeedsDisplay()
                }
            })
        }

        return vc!
    }

    static func dismissKeyboard() {
        mailaddress.endEditing(true)
        password.endEditing(true)
    }

    //UI Definition
    static func checkConfigView() -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()

        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("ConnectingToMailServer", comment: ""), body: nil, videoURL: nil, inputView: view, buttonText: nil, actionBlock: nil)

        let vc = Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])!
        vc.pageControl = UIPageControl.init()
        vc.view.backgroundColor = defaultColor
        return vc
    }

    //UI Definition
    static func keyHandlingView() -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("CreateAndManageKeys", comment: ""), body: nil, videoURL: nil, inputView: view, buttonText: nil, actionBlock: nil)
        let vc = Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])
        vc?.pageControl = UIPageControl.init()
        vc?.view.backgroundColor = defaultColor
        return vc!
    }

    //UI Definition
    static func detailOnboarding(_ callback: @escaping () -> ()) -> UIViewController {

        let start = OnboardingContentViewController.content(withTitle: NSLocalizedString("WhatAShame", comment: ""), body: NSLocalizedString("CouldNotConnect", comment: ""), videoURL: nil, inputView: nil, buttonText: nil, actionBlock: nil)

        Onboarding.password.returnKeyType = .done
        password.text = UserManager.loadUserValue(.userPW) as? String
        mailaddress.text = UserManager.loadUserValue(.userAddr) as? String
        doWhenDone = { Void in }

        let email = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertMailAddressAndPassword", comment: ""), videoURL: nil, inputView: credentials, buttonText: nil, actionBlock: callback)
        username = UITextField.init()
        username.borderStyle = UITextBorderStyle.none
        username.keyboardType = UIKeyboardType.emailAddress
        username.autocorrectionType = UITextAutocorrectionType.no
        username.returnKeyType = .done
        username.delegate = textDelegate
        username.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        username.placeholder = NSLocalizedString("Username", comment: "")
        username.text = UserManager.loadUserValue(Attribute.userName) as? String
        username.textColor = textColor
        username.tintColor = textColor
        username.attributedPlaceholder = NSAttributedString.init(string: NSLocalizedString("Username", comment: ""), attributes: [NSForegroundColorAttributeName: textColor])

        let usernameUnderline = UIView.init(frame: CGRect.init(x: 0, y: username.frame.maxY, width: username.frame.width, height: 0.5))
        usernameUnderline.backgroundColor = textColor

        let userView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: username.frame.height + usernameUnderline.frame.height))
        userView.addSubview(username)
        userView.addSubview(usernameUnderline)

        let user = OnboardingContentViewController.content(withTitle: nil, body: NSLocalizedString("InsertUsername", comment: ""), videoURL: nil, inputView: userView, buttonText: nil, actionBlock: nil)

        imapServer.borderStyle = UITextBorderStyle.none
        imapServer.textColor = textColor
        imapServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        imapServer.text = UserManager.loadUserValue(Attribute.imapHostname) as? String
        imapServer.autocorrectionType = UITextAutocorrectionType.no
        imapServer.returnKeyType = .done
        imapServer.delegate = textDelegate

        let imapServerUnderline = UIView.init(frame: CGRect.init(x: 0, y: imapServer.frame.maxY, width: imapServer.frame.width, height: 0.5))
        imapServerUnderline.backgroundColor = textColor

        let imapLabel = UILabel.init()
        imapLabel.text = "IMAP-Port"

        imapLabel.textColor = textColor
        imapLabel.font = font
        imapLabel.numberOfLines = 0
        imapLabel.textAlignment = NSTextAlignment.center
        imapLabel.frame = CGRect.init(x: 0, y: imapServer.frame.height + imapServerUnderline.frame.height + padding, width: 50, height: 30)
        imapPort.borderStyle = UITextBorderStyle.none
        imapPort.text = "0"
        imapPort.textColor = textColor
        if let port = UserManager.loadUserValue(Attribute.imapPort) {
            imapPort.text = "\(port as! Int)"
        }
        imapPort.keyboardType = UIKeyboardType.numberPad
        imapPort.returnKeyType = .done
        imapPort.delegate = textDelegate
        imapPort.frame = CGRect.init(x: 0, y: imapServer.frame.height + padding + imapLabel.frame.height + padding, width: 50, height: 30)

        let imapPortUnderline = UIView.init(frame: CGRect.init(x: 0, y: imapPort.frame.maxY, width: imapPort.frame.width, height: 0.5))
        imapPortUnderline.backgroundColor = textColor

        let imap = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: imapServer.frame.height + imapServerUnderline.frame.height + padding + imapLabel.frame.height + padding + imapPort.frame.height + imapPortUnderline.frame.height))
        imap.addSubview(imapServer)
        imap.addSubview(imapServerUnderline)
        imap.addSubview(imapLabel)
        imap.addSubview(imapPort)
        imap.addSubview(imapPortUnderline)

        let imap1 = OnboardingContentViewController.content(withTitle: nil, body: "IMAP-Server", videoURL: nil, inputView: imap, buttonText: nil, actionBlock: nil)

        imapTransportEncryption = UIPickerView()
        imapTransDataDelegate = PickerDataDelegate.init(rows: Array(transportRows.values))
        imapTransportEncryption.dataSource = imapTransDataDelegate
        imapTransportEncryption.delegate = imapTransDataDelegate
        imapTransportEncryption.frame = CGRect.init(x: 0, y: 0, width: 50, height: 100)
        imapTransportEncryption.reloadAllComponents()
        var row = UserManager.loadUserValue(Attribute.imapConnectionType) as! Int
        imapTransDataDelegate.pickedValue = transportRows[row]!
        row = imapTransDataDelegate.rows.index(of: transportRows[row]!)!
        imapTransportEncryption.selectRow(row, inComponent: 0, animated: false)

        let imapAuthLabel = UILabel.init()
        imapAuthLabel.text = "IMAP-" + NSLocalizedString("Authentification", comment: "")

        imapAuthLabel.textColor = UIColor.white;
        imapAuthLabel.font = font
        imapAuthLabel.numberOfLines = 0;
        imapAuthLabel.textAlignment = NSTextAlignment.center;
        imapAuthLabel.frame = CGRect.init(x: 0, y: imapTransportEncryption.frame.height, width: 50, height: 30)

        imapAuthentication = UIPickerView()
        imapAuthDataDelegate = PickerDataDelegate.init(rows: Array(authenticationRows.values))
        imapAuthentication.dataSource = imapAuthDataDelegate
        imapAuthentication.delegate = imapAuthDataDelegate
        imapAuthentication.frame = CGRect.init(x: 0, y: imapTransportEncryption.frame.height + imapAuthLabel.frame.height, width: 50, height: 100)
        imapAuthentication.reloadAllComponents()
        imapAuthentication.reloadInputViews()
        imapAuthentication.tintColor = textColor
        row = UserManager.loadUserValue(Attribute.imapAuthType) as! Int
        imapAuthDataDelegate.pickedValue = authenticationRows[row]!
        row = Array(authenticationRows.values).index(of: authenticationRows[row]!)!
        imapAuthentication.selectRow(row, inComponent: 0, animated: false)

        let imapAuth = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: imapTransportEncryption.frame.height + padding + imapAuthLabel.frame.height + imapAuthentication.frame.height))
        imapAuth.addSubview(imapTransportEncryption)
        imapAuth.addSubview(imapAuthLabel)
        imapAuth.addSubview(imapAuthentication)
        let boolPointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        boolPointer[0] = false
        let imap2 = OnboardingContentViewController.content(withTitle: nil, body: "IMAP-" + NSLocalizedString("Transportencryption", comment: ""), videoURL: nil, inputView: imapAuth, buttonText: nil, actionBlock: nil, withPadding: boolPointer)


        smtpServer.borderStyle = UITextBorderStyle.none
        smtpServer.textColor = textColor
        smtpServer.text = UserManager.loadUserValue(Attribute.smtpHostname) as? String
        smtpServer.frame = CGRect.init(x: 0, y: 0, width: 50, height: 30)
        smtpServer.autocorrectionType = UITextAutocorrectionType.no
        smtpServer.returnKeyType = .done
        smtpServer.delegate = textDelegate

        let smtpServerUnderline = UIView.init(frame: CGRect.init(x: 0, y: smtpServer.frame.maxY, width: smtpServer.frame.width, height: 0.5))
        smtpServerUnderline.backgroundColor = textColor

        let smtpLabel = UILabel.init()
        smtpLabel.text = "SMTP-Port"

        smtpLabel.textColor = textColor;
        smtpLabel.font = font
        smtpLabel.numberOfLines = 0;
        smtpLabel.textAlignment = NSTextAlignment.center;
        smtpLabel.frame = CGRect.init(x: 0, y: smtpServer.frame.height + smtpServerUnderline.frame.height + padding, width: 50, height: 30)
        smtpPort.borderStyle = UITextBorderStyle.roundedRect
        smtpPort.text = "0"
        smtpPort.textColor = textColor
        smtpPort.borderStyle = UITextBorderStyle.none
        if let port = UserManager.loadUserValue(Attribute.smtpPort) {
            smtpPort.text = "\(port as! Int)"
        }
        smtpPort.keyboardType = UIKeyboardType.numberPad
        smtpPort.returnKeyType = .done
        smtpPort.delegate = textDelegate
        smtpPort.frame = CGRect.init(x: 0, y: smtpServer.frame.height + smtpServerUnderline.frame.height + padding + smtpLabel.frame.height + padding, width: 50, height: 30)

        let smtpPortUnderline = UIView.init(frame: CGRect.init(x: 0, y: smtpPort.frame.maxY, width: smtpPort.frame.width, height: 0.5))
        smtpPortUnderline.backgroundColor = textColor

        let smtp = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: smtpServer.frame.height + smtpServerUnderline.frame.height + padding + smtpLabel.frame.height + padding + smtpPort.frame.height + smtpPortUnderline.frame.height))
        smtp.addSubview(smtpServer)
        smtp.addSubview(smtpServerUnderline)
        smtp.addSubview(smtpLabel)
        smtp.addSubview(smtpPort)
        smtp.addSubview(smtpPortUnderline)

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
        smtpAuthLabel.text = "SMTP-" + NSLocalizedString("Authentification", comment: "")

        smtpAuthLabel.textColor = UIColor.white;
        smtpAuthLabel.font = font
        smtpAuthLabel.numberOfLines = 0;
        smtpAuthLabel.textAlignment = NSTextAlignment.center;
        smtpAuthLabel.frame = CGRect.init(x: 0, y: smtpTransportEncryption.frame.height, width: 50, height: 30)

        smtpAuthentication = UIPickerView()
        smtpAuthDataDelegate = PickerDataDelegate.init(rows: Array(authenticationRows.values))
        smtpAuthentication.dataSource = smtpAuthDataDelegate
        smtpAuthentication.delegate = smtpAuthDataDelegate
        smtpAuthentication.frame = CGRect.init(x: 0, y: smtpTransportEncryption.frame.height + smtpAuthLabel.frame.height, width: 50, height: 100)
        smtpAuthentication.reloadAllComponents()
        smtpAuthentication.reloadInputViews()
        smtpAuthentication.tintColor = textColor
        row = UserManager.loadUserValue(Attribute.smtpAuthType) as! Int
        smtpAuthDataDelegate.pickedValue = authenticationRows[row]!
        row = Array(authenticationRows.values).index(of: authenticationRows[row]!)!
        smtpAuthentication.selectRow(row, inComponent: 0, animated: false)

        let smtpAuth = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: smtpTransportEncryption.frame.height + padding + smtpAuthLabel.frame.height + smtpAuthentication.frame.height))
        smtpAuth.addSubview(smtpTransportEncryption)
        smtpAuth.addSubview(smtpAuthLabel)
        smtpAuth.addSubview(smtpAuthentication)
        boolPointer[0] = false
        let smtp2 = OnboardingContentViewController.content(withTitle: nil, body: "SMTP-" + NSLocalizedString("Transportencryption", comment: ""), videoURL: nil, inputView: smtpAuth, buttonText: nil, actionBlock: nil, withPadding: boolPointer)


        let last = OnboardingContentViewController.content(withTitle: NSLocalizedString("EverythingCorrect", comment: ""), body: nil, videoURL: nil, inputView: nil, buttonText: NSLocalizedString("next", comment: ""), actionBlock: callback)

        let vc = Onboard.OnboardingViewController(backgroundImage: background, contents: [start, email, user, imap1, imap2, smtp1, smtp2, last])
        vc?.view.backgroundColor = defaultColor
        return vc!
    }

    static func contactView(_ callback: @escaping () -> ()) -> UIViewController {
        let activity = UIActivityIndicatorView.init()
        activity.startAnimating()
        let view = UIView.init()
        view.addSubview(activity)
        view.frame = activity.frame
        let page1 = OnboardingContentViewController.content(withTitle: NSLocalizedString("AccessContacts", comment: ""), body: NSLocalizedString("AccessContactsDescription", comment: "Description, why we need access"), videoURL: nil, inputView: nil, buttonText: NSLocalizedString("GotIt", comment: ""), actionBlock: callback)

        let vc = Onboard.OnboardingViewController(backgroundImage: background, contents: [page1])!
        vc.pageControl = UIPageControl.init()
        vc.view.backgroundColor = defaultColor
        return vc
    }

    static func checkContact(_ callback: @escaping (Bool) -> ()) {
        AppDelegate.getAppDelegate().requestForAccess(callback)
    }

    static func checkConfig(_ fail: @escaping () -> (), work: @escaping () -> ()) -> Bool {
        self.work = work
        self.fail = fail
        AppDelegate.getAppDelegate().mailHandler.checkIMAP(imapCompletion)
        return true
    }

    static func imapCompletion(_ error: Error?) { //FIXME: vorher NSError? Mit Error? immer noch gültig?
        if error == nil {
            AppDelegate.getAppDelegate().mailHandler.checkSMTP(smtpCompletion)
            return
        }
        fail()
    }

    static func smtpCompletion(_ error: Error?) { //FIXME: vorher NSError? Mit Error? immer noch gültig?
        if error == nil {
            work()
            return
        }
        fail()
    }

    static func setValues() -> OnboardingValueState {

        if let mailAddress = mailaddress.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !manualSet && mailAddress != "" {
            let guessedUserName = mailAddress.components(separatedBy: "@")[0]
            UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.userName)
            if mailAddress.contains("@gmail") || mailAddress.contains("@googlemail") {
                UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userName)
            }
            else if mailAddress.contains("@gmx") {
                UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userName)
            }
            else if mailAddress.contains("@posteo") {
                UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userName)
            }
            else if mailAddress.contains("@aol.com") || mailAddress.contains("@games.com") || mailAddress.contains("@love.com") {
                UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userName)
            }
            UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userAddr)
            if let pw = password.text{
                print(pw)
                UserManager.storeUserValue(pw as AnyObject, attribute: Attribute.userPW)
            }
            //TODO: REMOVE BEFORE STUDY
            loadTestAcc()
            return setServerValues(mailaddress: mailAddress)
        }
        else{
            setDefaultValues()
            return OnboardingValueState.empty
        }
    }

    static func setServerValues(mailaddress: String) -> OnboardingValueState {
        let manager = MCOMailProvidersManager.shared()!
        let path = Bundle.main.path(forResource: "providers", ofType: "json")
        manager.registerProviders(withFilename: path)

        if let provider = manager.provider(forEmail: mailaddress), let imap = (provider.imapServices() as? [MCONetService]), imap != [], let smtp = (provider.smtpServices() as? [MCONetService]), smtp != [] {
            let imapService = imap[0]
            UserManager.storeUserValue((imapService.info()["hostname"] ?? "imap.web.de") as AnyObject?, attribute: Attribute.imapHostname)
            UserManager.storeUserValue((imapService.info()["port"] ?? 587) as AnyObject?, attribute: Attribute.imapPort)

            if let trans = imapService.info()["ssl"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
            } else if let trans = imapService.info()["starttls"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
            } else {
                UserManager.storeUserValue(MCOConnectionType.clear.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
            }

            if let auth = imapService.info()["auth"] as? String, auth == "saslPlain" {
                UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslLogin" {
                UserManager.storeUserValue(MCOAuthType.saslLogin.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslKerberosV4" {
                UserManager.storeUserValue(MCOAuthType.saslKerberosV4.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslCRAMMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslDIGESTMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLDIGESTMD5.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslGSSAPI" {
                UserManager.storeUserValue(MCOAuthType.SASLGSSAPI.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslSRP" {
                UserManager.storeUserValue(MCOAuthType.SASLSRP.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "saslNTLM" {
                UserManager.storeUserValue(MCOAuthType.SASLNTLM.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "xoAuth2" {
                UserManager.storeUserValue(MCOAuthType.xoAuth2.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else if let auth = imapService.info()["auth"] as? String, auth == "xoAuth2Outlook" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
            } else {
                UserManager.storeUserValue(0 as AnyObject?, attribute: Attribute.imapAuthType)
            }

            let smtpService = smtp[0]
            UserManager.storeUserValue((smtpService.info()["hostname"] ?? "smtp.web.de") as AnyObject?, attribute: Attribute.smtpHostname)
            UserManager.storeUserValue((smtpService.info()["port"] ?? 993) as AnyObject?, attribute: Attribute.smtpPort)

            if let trans = smtpService.info()["ssl"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
            } else if let trans = smtpService.info()["starttls"] as? Bool, trans {
                UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
            } else {
                UserManager.storeUserValue(MCOConnectionType.clear.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
            }

            if let auth = smtpService.info()["auth"] as? String, auth == "saslPlain" {
                UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslLogin" {
                UserManager.storeUserValue(MCOAuthType.saslLogin.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslKerberosV4" {
                UserManager.storeUserValue(MCOAuthType.saslKerberosV4.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslCRAMMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslDIGESTMD5" {
                UserManager.storeUserValue(MCOAuthType.SASLDIGESTMD5.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslGSSAPI" {
                UserManager.storeUserValue(MCOAuthType.SASLGSSAPI.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslSRP" {
                UserManager.storeUserValue(MCOAuthType.SASLSRP.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "saslNTLM" {
                UserManager.storeUserValue(MCOAuthType.SASLNTLM.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "xoAuth2" {
                UserManager.storeUserValue(MCOAuthType.xoAuth2.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else if let auth = smtpService.info()["auth"] as? String, auth == "xoAuth2Outlook" {
                UserManager.storeUserValue(MCOAuthType.SASLCRAMMD5.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
            } else {
                UserManager.storeUserValue(0 as AnyObject?, attribute: Attribute.smtpAuthType)
            }
            
            if let drafts = provider.draftsFolderPath() {
                UserManager.storeUserValue(drafts as AnyObject?, attribute: Attribute.draftFolderPath)
            }
            if let sent = provider.sentMailFolderPath() {
                UserManager.storeUserValue(sent as AnyObject?, attribute: Attribute.sentFolderPath)
            }
            if let trash = provider.trashFolderPath() {
                UserManager.storeUserValue(trash as AnyObject?, attribute: Attribute.trashFolderPath)
            }
            if let archive = provider.allMailFolderPath() {
                UserManager.storeUserValue(archive as AnyObject?, attribute: Attribute.archiveFolderPath)
            }
            return OnboardingValueState.fine
        }
        else {
            setDefaultValues()
            return OnboardingValueState.noJson
        }
    }

    static func setDefaultValues() {
        UserManager.storeUserValue("imap.example.de" as AnyObject?, attribute: Attribute.imapHostname)
        UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject?, attribute: Attribute.imapConnectionType)
        UserManager.storeUserValue(993 as AnyObject?, attribute: Attribute.imapPort)
        UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.imapAuthType)
        UserManager.storeUserValue("smtp.example.de" as AnyObject?, attribute: Attribute.smtpHostname)
        UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject?, attribute: Attribute.smtpConnectionType)
        UserManager.storeUserValue(587 as AnyObject?, attribute: Attribute.smtpPort)
        UserManager.storeUserValue(MCOAuthType.saslPlain.rawValue as AnyObject?, attribute: Attribute.smtpAuthType)
    }
    
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) { UnsafeRawPointer($0).load(as: T.self) }
            i = i + 1
            return next.hashValue == (i - 1) ? next : nil
        }
    }


    //Inspired by http://stackoverflow.com/questions/32692450/swift-dictionary-get-key-for-values
    static func keyForValue(_ dict: [Int: String], value: String) -> [Int] {
        let keys = dict.filter {
            return $0.1 == value
        }.map {
            return $0.0
        }
        return keys
    }
}

class TextFieldDelegate: NSObject, UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == Onboarding.mailaddress {
            textField.resignFirstResponder()
            Onboarding.password.becomeFirstResponder()
            return false
        } else if textField == Onboarding.password {
            textField.resignFirstResponder()
            Onboarding.doWhenDone()
            return true
        }
            else {
                textField.resignFirstResponder()
        }
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

class PickerDataDelegate: NSObject, UIPickerViewDataSource {
    var rows = ["Keine", "Normal, Password", "Login"]
    var pickedValue = ""

    init(rows: [String]) {
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
extension PickerDataDelegate: UIPickerViewDelegate {

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
        label.font = Onboarding.font?.withSize((Onboarding.font?.pointSize)! - CGFloat(5))
        label.textColor = UIColor.white
        return label
    }

    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickedValue = rows[row]
    }
}
