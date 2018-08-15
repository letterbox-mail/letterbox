//
//  OnboardingSetupLongPageViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 17.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingSetupLongPageViewController: UIPageViewController {
    
    var orderedViewControllers: [UIViewController] = []
    var pageControl = UIPageControl()
    
    let defaultColor = UIColor.darkGray
    
    var credentialsController: OnboardingTextInputViewController?
    var usernameController: OnboardingTextInputViewController?
    var imapServerController: OnboardingTextInputViewController?
    var imapConnectionController: OnboardingPickerInputViewController?
    var imapTransportDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.transportOptions.values))
    var imapAuthDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.authenticationOptions.values))
    var smtpServerController: OnboardingTextInputViewController?
    var smtpConnectionController: OnboardingPickerInputViewController?
    var smtpTransportDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.transportOptions.values))
    var smtpAuthDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.authenticationOptions.values))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        imapTransportDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.transportOptions.values))
        imapAuthDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.authenticationOptions.values))
        smtpTransportDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.transportOptions.values))
        smtpAuthDataDelegate = PickerDataDelegate.init(rows: Array(OnboardingDataHandler.handler.authenticationOptions.values))
        orderedViewControllers = createViewControllers()
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: false,
                               completion: nil)
        }
        pageControl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 50, width: UIScreen.main.bounds.width, height: 50))
        pageControl.numberOfPages = orderedViewControllers.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = UIColor.white
        self.view.backgroundColor = defaultColor
        view.addSubview(pageControl)
    }
    
    func createViewControllers() -> [UIViewController] {
        var array: [UIViewController] = []
        
        let introductionController =  UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "description_new") as! OnboardingDescriptionViewController
        introductionController.viewModification = { [weak self] in
            introductionController.titleLabel.text = NSLocalizedString("WhatAShame", comment: "")
            introductionController.descriptionText.text = NSLocalizedString("CouldNotConnect", comment: "")
            introductionController.descriptionText.textAlignment = NSTextAlignment.center
            introductionController.videoView.backgroundColor = self?.defaultColor
        }
        introductionController.pageControlDelegate = self
        array.append(introductionController)
        
        credentialsController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "textInputView") as! OnboardingTextInputViewController
        credentialsController!.viewModification = { [weak credentialsController] in
            credentialsController?.labelTop.text = NSLocalizedString("InsertMailAddressAndPassword", comment: "")
            credentialsController?.textFieldTop.keyboardType = UIKeyboardType.emailAddress
            credentialsController?.textFieldTop.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Address", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            credentialsController?.textFieldTop.autocorrectionType = UITextAutocorrectionType.no
            credentialsController?.textFieldTop.returnKeyType = UIReturnKeyType.continue
            credentialsController?.labelBottom.text = nil
            credentialsController?.textFieldBottom.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Password", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            if #available(iOS 11.0, *) {
                credentialsController?.textFieldBottom.textContentType = UITextContentType.password
            } else {
                //TODO: do we have to do here something?
            }
            credentialsController?.textFieldBottom.isSecureTextEntry = true
            credentialsController?.textFieldBottom.autocorrectionType = UITextAutocorrectionType.no
            credentialsController?.textFieldBottom.returnKeyType = UIReturnKeyType.next
            //credentialsController?.keyboardAccessoryLeft = NSLocalizedString("LoginWithGoogle", comment: "Login via google oauth")
        }
        credentialsController!.pageControlDelegate = self
        credentialsController!.textInputDelegate = self
        array.append(credentialsController!)
        
        usernameController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "textInputView") as! OnboardingTextInputViewController
        usernameController!.viewModification = { [weak usernameController] in
            usernameController?.labelTop.text = NSLocalizedString("InsertUsername", comment: "")
            usernameController?.textFieldTop.keyboardType = UIKeyboardType.emailAddress
            usernameController?.textFieldTop.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Username", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            usernameController?.textFieldTop.returnKeyType = .next
            usernameController?.labelBottom.text = nil
            usernameController?.disableSecondSection = true
        }
        usernameController!.pageControlDelegate = self
        usernameController!.textInputDelegate = self
        array.append(usernameController!)
        
        imapServerController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "textInputView") as! OnboardingTextInputViewController
        imapServerController!.viewModification = { [weak imapServerController] in
            imapServerController?.labelTop.text = NSLocalizedString("IMAP-Server", comment: "")
            imapServerController?.textFieldTop.keyboardType = UIKeyboardType.URL
            imapServerController?.textFieldTop.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("IMAP-Server", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            imapServerController?.textFieldTop.autocorrectionType = UITextAutocorrectionType.no
            imapServerController?.textFieldTop.returnKeyType = UIReturnKeyType.continue
            imapServerController?.labelBottom.text = NSLocalizedString("IMAP-Port", comment: "")
            imapServerController?.textFieldBottom.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("IMAP-Port", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            imapServerController?.textFieldBottom.keyboardType = UIKeyboardType.numberPad
            imapServerController?.textFieldBottom.autocorrectionType = UITextAutocorrectionType.no
            imapServerController?.textFieldBottom.returnKeyType = UIReturnKeyType.next
        }
        imapServerController!.pageControlDelegate = self
        imapServerController!.textInputDelegate = self
        array.append(imapServerController!)
        
        imapConnectionController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "pickerInputView") as! OnboardingPickerInputViewController
        imapConnectionController!.viewModification = { [weak imapConnectionController, weak self] in
            imapConnectionController?.labelTop.text = NSLocalizedString("IMAP-Transportencryption", comment: "")
            imapConnectionController?.pickerViewTop.dataSource = self?.imapTransportDataDelegate
            imapConnectionController?.pickerViewTop.delegate = self?.imapTransportDataDelegate

            imapConnectionController?.labelBottom.text = NSLocalizedString("IMAP-Authentification", comment: "")
            imapConnectionController?.pickerViewBottom.dataSource = self?.imapAuthDataDelegate
            imapConnectionController?.pickerViewBottom.delegate = self?.imapAuthDataDelegate
        }
        imapConnectionController!.pageControlDelegate = self
        array.append(imapConnectionController!)
        
        smtpServerController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "textInputView") as! OnboardingTextInputViewController
        smtpServerController!.viewModification = { [weak smtpServerController] in
            smtpServerController?.labelTop.text = NSLocalizedString("SMTP-Server", comment: "")
            smtpServerController?.textFieldTop.keyboardType = UIKeyboardType.URL
            smtpServerController?.textFieldTop.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("SMTP-Server", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            smtpServerController?.textFieldTop.autocorrectionType = UITextAutocorrectionType.no
            smtpServerController?.textFieldTop.returnKeyType = UIReturnKeyType.continue
            smtpServerController?.labelBottom.text = NSLocalizedString("SMTP-Port", comment: "")
            smtpServerController?.textFieldBottom.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("SMTP-Port", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            smtpServerController?.textFieldBottom.keyboardType = UIKeyboardType.numberPad
            smtpServerController?.textFieldBottom.autocorrectionType = UITextAutocorrectionType.no
            smtpServerController?.textFieldBottom.returnKeyType = UIReturnKeyType.next
        }
        smtpServerController!.pageControlDelegate = self
        smtpServerController!.textInputDelegate = self
        array.append(smtpServerController!)
        
        smtpConnectionController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "pickerInputView") as! OnboardingPickerInputViewController
        smtpConnectionController!.viewModification = { [weak smtpConnectionController, weak self] in
            smtpConnectionController?.labelTop.text = NSLocalizedString("SMTP-Transportencryption", comment: "")
            smtpConnectionController?.pickerViewTop.dataSource = self?.smtpTransportDataDelegate
            smtpConnectionController?.pickerViewTop.delegate = self?.smtpTransportDataDelegate
            
            smtpConnectionController?.labelBottom.text = NSLocalizedString("SMTP-Authentification", comment: "")
            smtpConnectionController?.pickerViewBottom.dataSource = self?.smtpAuthDataDelegate
            smtpConnectionController?.pickerViewBottom.delegate = self?.smtpAuthDataDelegate
        }
        smtpConnectionController!.pageControlDelegate = self
        array.append(smtpConnectionController!)
        
        let confirmationController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "confirmationView") as! OnboardingConfirmationViewController
        confirmationController.viewModification = {
            confirmationController.labelTop.text = NSLocalizedString("EverythingCorrect", comment: "")
            confirmationController.scanButton.setTitle(NSLocalizedString("next", comment: ""), for: UIControlState.normal)
        }
        confirmationController.confirmationDelegate = self
        confirmationController.pageControlDelegate = self
        array.append(confirmationController)
        
        return array
    }
    
    func presentController(behind viewController: UIViewController?) {
        if viewController != nil, let currentIndex = orderedViewControllers.index(of: viewController!), currentIndex+1 < orderedViewControllers.count {
            setViewControllers([orderedViewControllers[currentIndex+1]], direction: .forward, animated: true, completion: nil)
        }
    }
}
extension OnboardingSetupLongPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = orderedViewControllers.index(of: viewController), index > 0 {
            return orderedViewControllers[index-1]
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = orderedViewControllers.index(of: viewController), index < orderedViewControllers.count-1 {
            return orderedViewControllers[index+1]
        }
        return nil
    }
    
    
}

extension OnboardingSetupLongPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let previous = previousViewControllers.last {
            pageControl.currentPage = orderedViewControllers.index(of: previous)!
        } else {
            pageControl.currentPage = 0
        }
    }
}

extension OnboardingSetupLongPageViewController: OnboardingPageControlDelegate {
    func contentViewControllerDidAppear(viewController: UIViewController) {
        if let index = orderedViewControllers.index(of: viewController) {
            pageControl.currentPage = index
            pageControl.updateCurrentPageDisplay()
        }
    }
}

extension OnboardingSetupLongPageViewController: OnboardingTextInputDelegate {
    func leftKeyboardButton(viewController: OnboardingTextInputViewController) {
        //TODO: google oauth
    }
    
    func rightKeyboardButton(viewController: OnboardingTextInputViewController) {
        viewController.view.endEditing(true)
    }
    
    func nextButtonTapped(viewController: OnboardingTextInputViewController) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == credentialsController?.textFieldTop {
            credentialsController?.textFieldBottom.becomeFirstResponder()
        }
        else if textField == credentialsController?.textFieldBottom {
            presentController(behind: credentialsController)
        }
        else if textField == usernameController?.textFieldTop {
            presentController(behind: usernameController)
        }
        else if textField == imapServerController?.textFieldTop {
            imapServerController?.textFieldBottom.becomeFirstResponder()
        }
        else if textField == imapServerController?.textFieldBottom {
            presentController(behind: imapServerController)
        }
        else if textField == smtpServerController?.textFieldTop {
            smtpServerController?.textFieldBottom.becomeFirstResponder()
        }
        else if textField == smtpServerController?.textFieldBottom {
            presentController(behind: smtpServerController)
        }
        return true
    }
}

extension OnboardingSetupLongPageViewController: OnboardingConfirmationDelegate {
    func confirmationButtonTapped(viewController: OnboardingConfirmationViewController) {
        let onboardingDataHandler = OnboardingDataHandler.handler
        var mailaddress = ""
        var password = ""
        var username = ""
        var imapServer = ""
        var imapPort = 0
        var imapEncryption = MCOConnectionType.clear.rawValue
        var imapAuthentification = MCOAuthType.saslPlain.rawValue
        var smtpServer = ""
        var smtpPort = 0
        var smtpEncryption = MCOConnectionType.clear.rawValue
        var smtpAuthentification = MCOAuthType.saslPlain.rawValue
        //TODO add more
        
        if let controller = credentialsController {
            mailaddress = controller.textFieldTop.text ?? ""
            password = controller.textFieldBottom.text ?? ""
        }
        if let controller = usernameController {
            username = controller.textFieldTop.text ?? ""
        }
        if let controller = imapServerController {
            imapServer = controller.textFieldTop.text ?? ""
            imapPort = Int(controller.textFieldBottom.text ?? "0") ?? 0
        }
        if let controller = imapConnectionController {
            imapEncryption = controller.pickerViewTop.selectedRow(inComponent: 0)
            imapAuthentification = controller.pickerViewBottom.selectedRow(inComponent: 0)
        }
        if let controller = smtpServerController {
            smtpServer = controller.textFieldTop.text ?? ""
            smtpPort = Int(controller.textFieldBottom.text ?? "0") ?? 0
        }
        if let controller = smtpConnectionController {
            smtpEncryption = controller.pickerViewTop.selectedRow(inComponent: 0)
            smtpAuthentification = controller.pickerViewBottom.selectedRow(inComponent: 0)
        }
        
        onboardingDataHandler.setSettings(with: mailaddress, password: password, username: username, imapServer: imapServer, imapPort: imapPort, imapConnectionType: imapEncryption, imapAuthenticationType: imapAuthentification, smtpServer: smtpServer, smtpPort: smtpPort, smtpConnectionType: smtpEncryption, smtpAuthenticationType: smtpAuthentification)
        let setupController = self.storyboard?.instantiateViewController(withIdentifier: "validateSetupLong") as! OnboardingValidateSetupLongPageViewController
        self.present(setupController, animated: true, completion: nil)
    }
}
