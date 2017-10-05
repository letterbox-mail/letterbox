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
    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //UINavigationBar.appearance().backgroundColor = UIColor.blueColor()
       // loadTestAcc()

        resetApp()
        if (!UserDefaults.standard.bool(forKey: "launchedBefore")) {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            //self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("onboarding")
            self.window?.rootViewController = Onboarding.onboarding(self.credentialCheck)
            self.window?.makeKeyAndVisible()

            
        } else {
            presentInboxViewController()
        }
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    func credentialCheck() {
        self.window?.rootViewController = Onboarding.checkConfigView()
        Onboarding.setValues()
        if !Onboarding.checkConfig(self.credentialsFailed, work: self.credentialsWork) {
            self.window?.rootViewController = Onboarding.detailOnboarding(self.credentialCheck)
            return
        }
    }

    func credentialsFailed() {
        Onboarding.credentialFails += 1
        if Onboarding.credentialFails >= 3 {
            Onboarding.manualSet = true
            self.window?.rootViewController = Onboarding.detailOnboarding(self.credentialCheck)
        } else {
            Onboarding.manualSet = false
            let contr = (Onboarding.onboarding(self.credentialCheck) as! OnboardingViewController)
            self.window?.rootViewController = contr
            contr.gotoLastPage()
        }
    }

    func credentialsWork() {
        self.window?.rootViewController = Onboarding.contactView(self.requestForAccess)
        //self.onboardingDone()
    }

    func contactCheck(_ accessGranted: Bool) {
        if accessGranted {
            self.setupKeys()
        } else {
            //self.onboardingDone()
            DispatchQueue.main.async(execute: {
                self.showMessage(NSLocalizedString("AccessNotGranted", comment: ""), completion: self.setupKeys)
            });
        }
    }

    func resetApp() {
        if UserDefaults.standard.bool(forKey: "reset") {
            if UserManager.loadUserValue(Attribute.userAddr) as! String == "ullimuelle@web.de" {
                let mailhandler = MailHandler.init()
                //mailhandler.move(mails: DataHandler.handler.findFolder(name: "INBOX").mailsOfFolder, from: "INBOX", to: "Archive")
            }
            DataHandler.handler.reset()
            Onboarding.credentials = nil
            Onboarding.credentialFails = 0
            Onboarding.manualSet = false
            UserManager.resetUserValues()
           
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            //self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("onboarding")
            self.window?.rootViewController = Onboarding.onboarding(self.credentialCheck)
            self.window?.makeKeyAndVisible()
            UserDefaults.standard.set(false, forKey: "launchedBefore")
            UserDefaults.standard.set(false, forKey: "reset")
        }
    }

    func setupKeys() {
        self.window?.rootViewController = Onboarding.keyHandlingView()
        DispatchQueue.main.async(execute: {
            //loadUlli()
            
            self.onboardingDone()
        });
    }

    func onboardingDone() {
        /*self.window?.rootViewController = Onboarding.keyHandlingView()
        Onboarding.keyHandling()*/
        UserDefaults.standard.set(true, forKey: "launchedBefore")
        self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        presentInboxViewController()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //DataHandler.handler.terminate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        resetApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        DataHandler.handler.terminate()
    }


    class func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }


    func showMessage(_ message: String, completion: (() -> Void)?) {
        let alertController = UIAlertController(title: "Enzevalos", message: message, preferredStyle: UIAlertControllerStyle.alert)

        let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action: UIAlertAction) -> Void in
            if let cb = completion {
                cb()
            }
        }

        alertController.addAction(dismissAction)

        //let pushedViewControllers = (self.window?.rootViewController as! UINavigationController).viewControllers
        let presentedViewController = self.window!.rootViewController!//pushedViewControllers[pushedViewControllers.count - 1]

        presentedViewController.present(alertController, animated: false, completion: nil)
    }


    func requestForAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)

        switch authorizationStatus {
        case .authorized:
            completionHandler(true)

        case .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(access)
                } else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        /*dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message, completion: nil)
                        })*/
                    }
                    completionHandler(false)
                }
            })

        default:
            completionHandler(false)
        }
    }

    func requestForAccess() {
        self.requestForAccess(self.contactCheck)
    }

    func presentInboxViewController() {
        let rootViewController = (self.window?.rootViewController! as! UINavigationController)
        mailHandler.allContacts(inbox: "INBOX")

        for vc in rootViewController.viewControllers {
            if let id = vc.restorationIdentifier, id == "folderViewController" {
                let inboxViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inboxViewController")
                vc.title = NSLocalizedString("Folders", comment: "")
                rootViewController.pushViewController(inboxViewController, animated: false)
                break
            }
        }
    }
}

struct AppUtility {
    // https://stackoverflow.com/a/41811798

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {

        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {

        self.lockOrientation(orientation)

        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
}
