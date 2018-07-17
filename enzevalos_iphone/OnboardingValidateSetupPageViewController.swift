//
//  OnboardingValidateSetupPageViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 17.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingValidateSetupPageViewController: UIPageViewController {
    
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
        
        let duration = 0.5
        
        let spinnerController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "spinnerView") as! OnboardingSpinnerViewController
        spinnerController.viewModification = {
            spinnerController.labelTop.text = NSLocalizedString("ConnectingToMailServer", comment: "")
        }
        spinnerController.pageControlDelegate = self
        array.append(spinnerController)
        
        return array
    }
}
extension OnboardingValidateSetupPageViewController: UIPageViewControllerDataSource {
    
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
