//
//  OnboardingAccessContactsPageViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 17.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingAccessContactsPageViewController: UIPageViewController {
    
    var orderedViewControllers: [UIViewController] = []
    var pageControl = UIPageControl()
    
    let defaultColor = UIColor.darkGray
    
    
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
        
        let confirmationController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "confirmationView") as! OnboardingConfirmationViewController
        confirmationController.viewModification = {
            confirmationController.labelTop.text = NSLocalizedString("AccessContactsDescription", comment: "Description, why we need access")
            confirmationController.scanButton.setTitle(NSLocalizedString("GotIt", comment: ""), for: UIControlState.normal)
        }
        array.append(confirmationController)
        
        return array
    }
}
extension OnboardingAccessContactsPageViewController: UIPageViewControllerDataSource {
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

extension OnboardingAccessContactsPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let previous = previousViewControllers.last {
            pageControl.currentPage = orderedViewControllers.index(of: previous)!
        } else {
            pageControl.currentPage = 0
        }
    }
}

extension OnboardingAccessContactsPageViewController: OnboardingPageControlDelegate {
    func contentViewControllerDidAppear(viewController: UIViewController) {
        if let index = orderedViewControllers.index(of: viewController) {
            pageControl.currentPage = index
            pageControl.updateCurrentPageDisplay()
        }
    }
}

extension OnboardingAccessContactsPageViewController: OnboardingConfirmationDelegate {
    func confirmationButtonTapped(viewController: OnboardingConfirmationViewController) {
        AppDelegate.getAppDelegate().requestForAccess()
    }
}
