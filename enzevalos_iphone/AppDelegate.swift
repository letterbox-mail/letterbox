//
//  AppDelegate.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 23.09.16.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit
import Contacts
import CoreData
import Onboard
import SystemConfiguration
import QAKit
import GTMAppAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var contactStore = CNContactStore()
    var mailHandler = MailHandler()
    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //UINavigationBar.appearance().backgroundColor = UIColor.blueColor()
        
        if UIScreen.main.bounds.height < 700 {
            kDefaultImageViewSize = 20
            kDefaultTitleFontSize = 33
            kDefaultBodyFontSize = 23
        }
        
        resetApp()
        StudySettings.setupStudy()
       // StudySettings.firstMail()
        if (!UserDefaults.standard.bool(forKey: "launchedBefore")) {
//            Logger.queue.async(flags: .barrier) {
                Logger.log(startApp: true)
//            }
            // Remove Google Auth token from keychain
            GTMKeychain.removePasswordFromKeychain(forName: "googleOAuthCodingKey")

            // Register defaults for signature handling
            UserDefaults.standard.register(defaults: ["Signature.Switch": true])
            UserDefaults.standard.register(defaults: ["Signature.Text": "Verfasst mit Letterbox. Mehr Informationen: http://letterbox.imp.fu-berlin.de?invitation=0"])
            
            self.window = UIWindow(frame: UIScreen.main.bounds)
            //self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("onboarding")
            self.window?.rootViewController = Onboarding.onboarding(self.credentialCheck)
            self.window?.makeKeyAndVisible()

            
        } else {
            AddressHandler.updateCNContacts()
//            Logger.queue.async(flags: .barrier) {
                Logger.log(startApp: false)
//            }
            presentInboxViewController()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addressBookDidChange),
            name: NSNotification.Name.CNContactStoreDidChange,
            object: nil)

		if #available(iOS 11.0, *) {
			QAKit.Fingertips.start()
		}

        return true
    }
    
    @objc func addressBookDidChange(notification: NSNotification){
        AddressHandler.updateCNContacts()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.absoluteURL.absoluteString.hasPrefix("com.googleusercontent.apps.459157836079-csn0a9p3r8p7q6216fn5u7a6vcum80gn") {
            if let currentAuthorizationFlow = EmailHelper.singleton().currentAuthorizationFlow {
                if currentAuthorizationFlow.resumeAuthorizationFlow(with: url) {
                    EmailHelper.singleton().currentAuthorizationFlow = nil
                    return true
                }
            }
        }
        
        return false
    }
    
    func googleLogin(vc: UIViewController) {
        Logger.log(onboardingState: "oAuth")
        if self.currentReachabilityStatus == .notReachable {
            let alert = UIAlertController(title: NSLocalizedString("Error.noInternet.Title", comment: ""), message: NSLocalizedString("Error.noInternet.Message", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "On", style: .default, handler: { [weak self] _ in
                let contr = (Onboarding.onboarding((self?.credentialCheck)!) as! OnboardingViewController)
                self?.window?.rootViewController = contr
                contr.gotoLastPage()
            }))
            self.window?.rootViewController?.present(alert, animated: true)
        } else {
            EmailHelper.singleton().doEmailLoginIfRequired(onVC: vc, completionBlock: {
                guard let userEmail = EmailHelper.singleton().authorization?.userEmail, EmailHelper.singleton().authorization?.canAuthorize() ?? false else {
                    print("Google authetication failed")
                    self.credentialsFailed()
                    return
                }
                UserManager.storeUserValue(userEmail as AnyObject, attribute: Attribute.userName)
                UserManager.storeUserValue(userEmail as AnyObject, attribute: Attribute.userAddr)
                UserManager.storeUserValue("imap.gmail.com" as AnyObject, attribute: Attribute.imapHostname)
                UserManager.storeUserValue(993 as AnyObject, attribute: Attribute.imapPort)
                UserManager.storeUserValue(MCOConnectionType.TLS.rawValue as AnyObject, attribute: Attribute.imapConnectionType)
                UserManager.storeUserValue(MCOAuthType.xoAuth2.rawValue as AnyObject, attribute: Attribute.imapAuthType)
                UserManager.storeUserValue("smtp.gmail.com" as AnyObject, attribute: Attribute.smtpHostname)
                UserManager.storeUserValue(587 as AnyObject, attribute: Attribute.smtpPort)
                UserManager.storeUserValue(MCOConnectionType.startTLS.rawValue as AnyObject, attribute: Attribute.smtpConnectionType)
                UserManager.storeUserValue(MCOAuthType.xoAuth2.rawValue as AnyObject, attribute: Attribute.smtpAuthType)

                Onboarding.checkConfig(self.credentialsFailed, work: self.credentialsWork)
            })
        }
    }
    
    func credentialCheck() {
        self.window?.rootViewController = Onboarding.checkConfigView()
        if Onboarding.googleAuth {
            Onboarding.googleAuth = false
            googleLogin(vc: self.window!.rootViewController!)
            return
        }
        if Onboarding.setValues() != OnboardingValueState.fine {
            credentialsFailed()
            return
        }
        
        Onboarding.checkConfig(self.credentialsFailed, work: self.credentialsWork)
    }

    func credentialsFailed() {
        Onboarding.credentialFails += 1
        if Onboarding.credentialFails >= 2 {
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
    }

    func contactCheck(_ accessGranted: Bool) {
        if accessGranted {
            setupKeys()
        } else {
            DispatchQueue.main.async(execute: {
                self.showMessage(NSLocalizedString("AccessNotGranted", comment: ""), completion: self.setupKeys)
            });
        }
    }

    // Option removed from Settings app, but this might still be usefull in the future
    func resetApp() {
        if UserDefaults.standard.bool(forKey: "reset") {
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
        let handler = DataHandler.init()
        _ = handler.createNewSecretKey(adr: UserManager.loadUserValue(Attribute.userAddr) as! String)
        StudySettings.setupStudyKeys()
        StudySettings.firstMail()
        DataHandler.handler.callForFolders(done: { err in
            for f in DataHandler.handler.allFolders {
            if f.flags.contains(MCOIMAPFolderFlag.drafts) {
                UserManager.storeUserValue(f.path as AnyObject?, attribute: Attribute.draftFolderPath)
            }
            if f.flags.contains(MCOIMAPFolderFlag.sentMail) {
                UserManager.storeUserValue(f.path as AnyObject?, attribute: Attribute.sentFolderPath)
            }
            if f.flags.contains(MCOIMAPFolderFlag.trash) {
                UserManager.storeUserValue(f.path as AnyObject?, attribute: Attribute.trashFolderPath)
            }
            if f.flags.contains(MCOIMAPFolderFlag.archive) {
                UserManager.storeUserValue(f.path as AnyObject?, attribute: Attribute.archiveFolderPath)
            }
            if f.flags.contains(MCOIMAPFolderFlag.inbox) {
                UserManager.storeUserValue(f.path as AnyObject?, attribute: Attribute.inboxFolderPath)
            }
            }
            DispatchQueue.main.async(execute: {
                self.onboardingDone()
            });})
    }

    func onboardingDone() {
//        Logger.queue.async(flags: .barrier) {
            Logger.log(onboardingState: "done")
//        }
        UserDefaults.standard.set(true, forKey: "launchedBefore")
        self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        presentInboxViewController()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        Logger.queue.async(flags: .barrier) {
            Logger.log(background: true)
//        }
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
//        Logger.queue.async(flags: .barrier) {
            Logger.log(background: false)
//        }
        resetApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        Logger.log(terminateApp: Void())
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

        presentedViewController.present(alertController, animated: true, completion: nil)
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

extension AppDelegate { //Network check
    
    //Inspired by https://stackoverflow.com/questions/39558868/check-internet-connection-ios-10
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
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
