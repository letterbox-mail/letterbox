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
    var smtpServerController: OnboardingTextInputViewController?
    var smtpConnectionController: OnboardingPickerInputViewController?
    var confirmationController: OnboardingConfirmationViewController?
    
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
        
        credentialsController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "textInputView") as! OnboardingTextInputViewController
        credentialsController!.viewModification = { [weak credentialsController] in
            credentialsController?.labelTop.text = NSLocalizedString("InsertMailAddressAndPassword", comment: "")
            credentialsController?.textFieldTop.placeholder = NSLocalizedString("Address", comment: "")
            credentialsController?.textFieldTop.keyboardType = UIKeyboardType.emailAddress
            credentialsController?.textFieldTop.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Address", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            credentialsController?.labelBottom.text = nil
            credentialsController?.textFieldBottom.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Password", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
            //credentialsController?.keyboardAccessoryLeft = NSLocalizedString("LoginWithGoogle", comment: "Login via google oauth")
        }
        credentialsController!.pageControlDelegate = self
        credentialsController!.textInputDelegate = self
        array.append(credentialsController!)
        
        return array
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
        
    }
    
    func rightKeyboardButton(viewController: OnboardingTextInputViewController) {
        viewController.view.endEditing(true)
    }
    
    func nextButtonTapped(viewController: OnboardingTextInputViewController) {
        if let top = viewController.textFieldTop.text, let bottom = viewController.textFieldBottom.text, top != "" && bottom != "" {
            let onboardingDataHandler = OnboardingDataHandler.handler
            onboardingDataHandler.setSettings(mailaddress: top, password: bottom)
            let setupController = self.storyboard?.instantiateViewController(withIdentifier: "validateSetup") as! OnboardingValidateSetupPageViewController
            self.present(setupController, animated: true, completion: nil)
        }
    }
}
