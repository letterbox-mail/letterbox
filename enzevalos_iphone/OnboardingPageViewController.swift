//
//  OnboardingPageViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 21.06.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingPageViewController: UIPageViewController {
    
    var orderedViewControllers: [UIViewController] = []
    var pageControl = UIPageControl()
    
    let defaultColor = UIColor.darkGray
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        orderedViewControllers = createViewControllers() //[UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "description")]
        
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
        view.addSubview(pageControl)
    }
    
    func createViewControllers() -> [UIViewController] {
        var array: [UIViewController] = []
        
        let duration = 0.5
        
        let welcomeController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "description_new") as! OnboardingDescriptionViewController
        welcomeController.viewModification = { [weak self] in
            welcomeController.titleLabel.text = NSLocalizedString("Welcome", comment: "Welcome")
            welcomeController.descriptionText.text = NSLocalizedString("ReadFollowingPages", comment: "")
            welcomeController.descriptionText.textAlignment = NSTextAlignment.center
            welcomeController.videoView.backgroundColor = self?.defaultColor
        }
        welcomeController.pageControlDelegate = self
        array.append(welcomeController)
        
        let letterController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "description_new") as! OnboardingDescriptionViewController
        letterController.viewModification = {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: letterController.icon.frame.width, height: letterController.icon.frame.height), false, 0)
            IconsStyleKit.drawLetter(frame: CGRect(x: 0, y: 0, width: letterController.icon.frame.width, height: letterController.icon.frame.height), fillBackground: true)
            letterController.icon.image = UIGraphicsGetImageFromCurrentImageContext()!
            letterController.titleLabel.text = NSLocalizedString("Letter", comment: "")
            letterController.descriptionText.text = NSLocalizedString("LetterDescription", comment: "describe the letter")
        }
        letterController.pageControlDelegate = self
        array.append(letterController)
        
        let postcardController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "description_new") as! OnboardingDescriptionViewController
        postcardController.viewModification = {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: postcardController.icon.frame.width, height: postcardController.icon.frame.height), false, 0)
            IconsStyleKit.drawPostcard(frame: CGRect(x: 0, y: 0, width: postcardController.icon.frame.width, height: postcardController.icon.frame.height), fillBackground: true)
            postcardController.icon.image = UIGraphicsGetImageFromCurrentImageContext()!
            postcardController.titleLabel.text = NSLocalizedString("Postcard", comment: "")
            postcardController.descriptionText.text = NSLocalizedString("PostcardDescription", comment: "describe the postcard")
        }
        postcardController.pageControlDelegate = self
        array.append(postcardController)
        
        let helpController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "description_new") as! OnboardingDescriptionViewController
        helpController.viewModification = {
            helpController.titleLabel.text = ""
            helpController.descriptionText.text = NSLocalizedString("GetHelp", comment: "")
            helpController.descriptionText.textAlignment = NSTextAlignment.center
            helpController.videoPath = Bundle.main.path(forResource: "videoOnboarding2", ofType: "m4v")
        }
        helpController.pageControlDelegate = self
        array.append(helpController)
        
        /*Colors*/
        self.view.backgroundColor = defaultColor
        
        welcomeController.viewWillAppearBlock = {
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { [weak self] in
                welcomeController.backgroundColor = self?.defaultColor
                letterController.backgroundColor = self?.defaultColor
            })
        }
        
        letterController.viewWillAppearBlock = {
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                welcomeController.backgroundColor = ThemeManager.encryptedMessageColor()
                letterController.backgroundColor = ThemeManager.encryptedMessageColor()
                postcardController.backgroundColor = ThemeManager.encryptedMessageColor()
                helpController.backgroundColor = ThemeManager.encryptedMessageColor()
            })
        }

        postcardController.viewWillAppearBlock = {
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    postcardController.backgroundColor = ThemeManager.unencryptedMessageColor()
                    letterController.backgroundColor = ThemeManager.unencryptedMessageColor()
                    helpController.backgroundColor = ThemeManager.unencryptedMessageColor()
                    postcardController.view.setNeedsDisplay()
            })
        }
        
        helpController.viewWillAppearBlock = {
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { [weak self] in
                postcardController.backgroundColor = self?.defaultColor
                helpController.backgroundColor = self?.defaultColor
            })
        }
        
        return array
    }
}
extension OnboardingPageViewController: UIPageViewControllerDataSource {
    
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

extension OnboardingPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let previous = previousViewControllers.last {
            pageControl.currentPage = orderedViewControllers.index(of: previous)!
        } else {
            pageControl.currentPage = 0
        }
    }
}

extension OnboardingPageViewController: OnboardingPageControlDelegate {
    func contentViewControllerDidAppear(viewController: UIViewController) {
        if let index = orderedViewControllers.index(of: viewController) {
            pageControl.currentPage = index
            pageControl.updateCurrentPageDisplay()
        }
    }
}
