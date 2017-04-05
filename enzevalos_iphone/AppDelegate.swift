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
    private var initialViewController : UIViewController? = nil
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        //UINavigationBar.appearance().backgroundColor = UIColor.blueColor()
        ThemeManager.currentTheme()
        
        if (!NSUserDefaults.standardUserDefaults().boolForKey("launchedBefore")) {
            self.initialViewController = self.window?.rootViewController
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            //self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("onboarding")
            self.window?.rootViewController = Onboarding.onboarding(self.credentialCheck)
            self.window?.makeKeyAndVisible()
        }
        return true
    }
    
    func credentialCheck() {
        self.window?.rootViewController = Onboarding.checkConfigView()
        Onboarding.setGuessValues()
        if !Onboarding.checkConfig(self.credentialsFailed, work: self.credentialsWork) {
            self.window?.rootViewController = Onboarding.detailOnboarding(self.credentialCheck)
            return
        }
    }
    
    func credentialsFailed(){
        self.window?.rootViewController = Onboarding.detailOnboarding(self.credentialCheck)
    }
    
    func credentialsWork() {
        self.window?.rootViewController = Onboarding.contactView(self.requestForAccess)
        //self.onboardingDone()
    }
    
    func contactCheck(accessGranted: Bool) {
        if accessGranted {
            self.onboardingDone()
        }
        else {
            //self.onboardingDone()
            dispatch_async(dispatch_get_main_queue(),{
                self.showMessage(NSLocalizedString("AccessNotGranted", comment: ""), completion: self.onboardingDone)
            });
        }
    }
    
    func onboardingDone() {
        self.window?.rootViewController = Onboarding.keyHandlingView()
        Onboarding.keyHandling()
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
        self.window?.rootViewController = self.initialViewController!
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
        let alertController = UIAlertController(title: "Enzevalos", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action : UIAlertAction) -> Void in
            if let cb = completion {
                cb()
            }
        }
        
        alertController.addAction(dismissAction)
        
        //let pushedViewControllers = (self.window?.rootViewController as! UINavigationController).viewControllers
        let presentedViewController = self.window!.rootViewController!//pushedViewControllers[pushedViewControllers.count - 1]
        
        presentedViewController.presentViewController(alertController, animated: false, completion: nil)
    }
    
    
    func requestForAccess(completionHandler: (accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        
        switch authorizationStatus {
        case .Authorized:
            completionHandler(accessGranted: true)
            
        case .NotDetermined:
            self.contactStore.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(accessGranted: access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        /*dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message, completion: nil)
                        })*/
                    }
                    completionHandler(accessGranted: false)
                }
            })
            
        default:
            completionHandler(accessGranted: false)
        }
    }
    
    func requestForAccess() {
        self.requestForAccess(self.contactCheck)
    }
}

