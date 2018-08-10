//
//  OnboardingSetupPageViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 17.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingSetupPageViewController: UIPageViewController {
    
    var orderedViewControllers: [UIViewController] = []
    var pageControl = UIPageControl()
    
    let defaultColor = UIColor.darkGray
    
    var credentialsController: OnboardingTextInputViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        orderedViewControllers = createViewControllers()
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: false,
                               completion: nil)
        }
        self.view.backgroundColor = defaultColor
    }
    
    func createViewControllers() -> [UIViewController] {
        var array: [UIViewController] = []
        
        credentialsController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "textInputView") as! OnboardingTextInputViewController
        credentialsController?.viewModification = { [weak credentialsController] in
            credentialsController?.labelTop.text = NSLocalizedString("InsertMailAddressAndPassword", comment: "")
            credentialsController?.textFieldTop.keyboardType = UIKeyboardType.emailAddress
            credentialsController?.textFieldTop.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Address", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            credentialsController?.textFieldTop.autocorrectionType = UITextAutocorrectionType.no
            credentialsController?.labelBottom.text = nil
            credentialsController?.textFieldBottom.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Password", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            if #available(iOS 11.0, *) {
                credentialsController?.textFieldBottom.textContentType = UITextContentType.password
            } else {
                //TODO: do we have to do here something?
            }
            credentialsController?.textFieldBottom.isSecureTextEntry = true
            credentialsController?.textFieldBottom.autocorrectionType = UITextAutocorrectionType.no
            credentialsController?.disableButton = false
            credentialsController?.nextButton.setTitle(NSLocalizedString("next", comment: ""), for: UIControlState.normal)
            //credentialsController.keyboardAccessoryLeft = NSLocalizedString("LoginWithGoogle", comment: "Login via google oauth")
        }
        credentialsController?.textInputDelegate = self
        array.append(credentialsController!)
        
        return array
    }
}
extension OnboardingSetupPageViewController: UIPageViewControllerDataSource {
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

extension OnboardingSetupPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let previous = previousViewControllers.last {
            pageControl.currentPage = orderedViewControllers.index(of: previous)!
        } else {
            pageControl.currentPage = 0
        }
    }
}

extension OnboardingSetupPageViewController: OnboardingPageControlDelegate {
    func contentViewControllerDidAppear(viewController: UIViewController) {
        if let index = orderedViewControllers.index(of: viewController) {
            pageControl.currentPage = index
            pageControl.updateCurrentPageDisplay()
        }
    }
}

extension OnboardingSetupPageViewController: OnboardingTextInputDelegate {
    func leftKeyboardButton(viewController: OnboardingTextInputViewController) {
        //TODO: add gmail support
    }
    
    func rightKeyboardButton(viewController: OnboardingTextInputViewController) {
        viewController.view.endEditing(true)
    }
    
    func nextButtonTapped(viewController: OnboardingTextInputViewController) {
        if let top = viewController.textFieldTop.text, let bottom = viewController.textFieldBottom.text, top != "" && bottom != "" {
            let onboardingDataHandler = OnboardingDataHandler.handler
            onboardingDataHandler.setSettings(mailaddress: top, password: bottom)
            let validationController = self.storyboard?.instantiateViewController(withIdentifier: "validateSetup") as! OnboardingValidateSetupPageViewController
            self.present(validationController, animated: false, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == credentialsController?.textFieldBottom {
            nextButtonTapped(viewController: credentialsController!)
        }
        if textField == credentialsController?.textFieldTop {
            credentialsController?.textFieldBottom.becomeFirstResponder()
        }
        return true
    }
}
