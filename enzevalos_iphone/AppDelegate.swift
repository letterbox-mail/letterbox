//
//  AppDelegate.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 23.09.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit
import Contacts
import CoreData
import Onboard


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var contactStore = CNContactStore()
    var mailHandler = MailHandler()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        //UINavigationBar.appearance().backgroundColor = UIColor.blueColor()
        ThemeManager.currentTheme()
        
        if (!NSUserDefaults.standardUserDefaults().boolForKey("launchedBefore")) {
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("onboarding") //onboarding()
            self.window?.makeKeyAndVisible()
        }
        return true
    }
    
    func onboarding() -> UIViewController {
        
        //Background
        var background: UIImage
        
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
        var page1 = OnboardingContentViewController.contentWithTitle("Hallo", body: "Schön, dass du dich für sichere Email interessierst!", image: nil, buttonText: "", action: nil)
        var page2 = OnboardingContentViewController.contentWithTitle("hallo", body: "adgjadsghk.jer", videoURL: nil, inputView: UITextField.init(), buttonText: nil, action: nil)
        
        return Onboard.OnboardingViewController(backgroundImage: background, contents: [page1, page2])
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //DataHandler.handler.terminate()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        DataHandler.handler.terminate()
    }
    
    
    class func getAppDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    
    func showMessage(message: String, completion: (() -> Void)? ) {
        let alertController = UIAlertController(title: "enzevalos-send", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
        }
        
        alertController.addAction(dismissAction)
        
        let pushedViewControllers = (self.window?.rootViewController as! UINavigationController).viewControllers
        let presentedViewController = pushedViewControllers[pushedViewControllers.count - 1]
        
        presentedViewController.presentViewController(alertController, animated: true, completion: completion)
    }
    
    
    func requestForAccess(completionHandler: (accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        
        switch authorizationStatus {
        case .Authorized:
            completionHandler(accessGranted: true)
            
        case .Denied, .NotDetermined:
            self.contactStore.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(accessGranted: access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message, completion: nil)
                        })
                    }
                }
            })
            
        default:
            completionHandler(accessGranted: false)
        }
    }
}

