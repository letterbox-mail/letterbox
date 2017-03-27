//
//  OnboardingViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 21.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import UIKit

class OnboardingViewController : UIViewController {
    
    var pKey = true
    var jKey = true
    var aKey = true
    var q1Key = true
    
    var smtpCheckDone = false
    var imapCheckDone = false
    
    var smtpCheck = false
    var imapCheck = false
    
    var mailaddress : UITextField? = nil
    var password : UITextField? = nil
    
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        EnzevalosEncryptionHandler.getEncryption(.PGP)?.printAllKeyIDs()
    }
    
    @IBAction func privateKey(sender: AnyObject, forEvent event: UIEvent) {
        pKey = !pKey
    }
    @IBAction func jakobKey(sender: AnyObject, forEvent event: UIEvent) {
        jKey = !jKey
    }
    @IBAction func aliceKey(sender: AnyObject, forEvent event: UIEvent) {
        aKey = !aKey
    }
    @IBAction func quizer1Key(sender: AnyObject, forEvent event: UIEvent) {
        q1Key = !q1Key
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        if segue.identifier == "onboarding" {
            var mAddr = ""
            var mPw = ""
            if let addr = mailaddress?.text where addr != "" {
                //if addr.componentsSeparatedByString("@")[1] != "web.de" {
                // naechste view
                //}
                /*let guessedUserName = addr.componentsSeparatedByString("@")[0]
                 UserManager.storeUserValue(addr, attribute: Attribute.UserAddr)//Attribute.attributeValues[Attribute.UserAddr] = addr
                 UserManager.storeUserValue(guessedUserName, attribute: Attribute.UserName)*/
                mAddr = addr
            }
            if let pw = password?.text where pw != "" {
                //UserManager.storeUserValue(pw, attribute: Attribute.UserPW)//Attribute.attributeValues[Attribute.UserPW] = pw
                mPw = pw
            }
            self.setGuessValues(mAddr, pw: mPw)
            for encType in iterateEnum(EncryptionType) {
                let encryption = EnzevalosEncryptionHandler.getEncryption(encType)
                if let enc = encryption {
                    enc.removeAllKeys()
                }
            }
            EnzevalosEncryptionHandler.getEncryption(.PGP)?.printAllKeyIDs()
            if pKey {
                //---------------------------------------
                //Import private Key BEGIN
                
                 var path = NSBundle.mainBundle().pathForResource("alice2005-private", ofType: "gpg")        //<---- Schlüsseldatei
                 if mAddr.containsString("@") && mAddr.componentsSeparatedByString("@")[1] == Provider.ENZEVALOS.rawValue {
                        path = NSBundle.mainBundle().pathForResource("quizer1-private", ofType: "asc")
                 }
                let pgp = ObjectivePGP.init()
                 pgp.importKeysFromFile(path!, allowDuplicates: false)
                 let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                 do {
                 let data = try pgp.keys[0].export()
                 enc?.addKey(data, forMailAddresses: [])
                 }
                 catch _ {}
                
                //Import private key END
                //---------------------------------------
            }
            if jKey {
                //---------------------------------------
                //Import public Key BEGIN
                
                 let path = NSBundle.mainBundle().pathForResource("JakobBode", ofType: "asc")               //<---- Schlüsseldatei
                 let pgp = ObjectivePGP.init()
                 pgp.importKeysFromFile(path!, allowDuplicates: false)
                 let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                 do {
                 let data = try pgp.keys[0].export()
                 enc?.addKey(data, forMailAddresses: ["jakob.bode@fu-berlin.de"])                           //<---- Emailadresse
                 }
                 catch _ {}
                
                //Import public key END
                //---------------------------------------
            }
            if aKey {
                //---------------------------------------
                //Import public Key BEGIN
                
                 let path = NSBundle.mainBundle().pathForResource("alice2005-public", ofType: "gpg")               //<---- Schlüsseldatei
                 let pgp = ObjectivePGP.init()
                 pgp.importKeysFromFile(path!, allowDuplicates: false)
                 let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                 do {
                 let data = try pgp.keys[0].export()
                 enc?.addKey(data, forMailAddresses: ["alice2005@web.de"])                           //<---- Emailadresse
                 }
                 catch _ {}
                
                //Import public key END
                //---------------------------------------
            }
            if q1Key {
                //---------------------------------------
                //Import public Key BEGIN
                
                let path = NSBundle.mainBundle().pathForResource("quizer1-public", ofType: "asc")               //<---- Schlüsseldatei
                let pgp = ObjectivePGP.init()
                pgp.importKeysFromFile(path!, allowDuplicates: false)
                let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                do {
                    let data = try pgp.keys[0].export()
                    enc?.addKey(data, forMailAddresses: ["quizer1@enzevalos.de"])                           //<---- Emailadresse
                }
                catch _ {}
                
                //Import public key END
                //---------------------------------------
            }
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
        }
    }
    
    func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
        var i = 0
        return anyGenerator {
            let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
            return next.hashValue == i++ ? next : nil
        }
    }
    
    func setGuessValues(mailAddress: String, pw: String) {
        if mailAddress != "" {
            let guessedUserName = mailAddress.componentsSeparatedByString("@")[0]
            let provider = mailAddress.componentsSeparatedByString("@")[1]
            UserManager.storeUserValue(mailAddress, attribute: Attribute.UserAddr)//Attribute.attributeValues[Attribute.UserAddr] = addr
            UserManager.storeUserValue(guessedUserName, attribute: Attribute.UserName)
            if provider == Provider.FU.rawValue {
                Providers.setValues(Provider.FU)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.Accountname)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.UserName)
            }
            if provider == Provider.ZEDAT.rawValue {
                Providers.setValues(Provider.ZEDAT)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.Accountname)
                UserManager.storeUserValue("jakobsbode", attribute: Attribute.UserName)
            }
            if provider == Provider.ENZEVALOS.rawValue {
                Providers.setValues(Provider.ENZEVALOS)
                UserManager.storeUserValue(guessedUserName, attribute: Attribute.Accountname)
                UserManager.storeUserValue(guessedUserName, attribute: Attribute.UserName)
            }
        }
        if pw != "" {
            UserManager.storeUserValue(pw, attribute: Attribute.UserPW)
        }
        smtpCheckDone = false
        imapCheckDone = false
        /*AppDelegate.getAppDelegate().mailHandler.checkSMTP(SMTPCompletion)
        AppDelegate.getAppDelegate().mailHandler.checkIMAP(IMAPCompletion)
        while (!imapCheckDone || !smtpCheckDone) {
            
        }*/
        print("checks ", imapCheck, smtpCheck)
    }
    
    private func SMTPCompletion(error: NSError?) {
        if error == nil {
            smtpCheck = true
        }
        smtpCheckDone = true
    }
    
    private func IMAPCompletion(error: NSError?) {
        if error == nil {
            imapCheck = true
        }
        imapCheckDone = true
    }
    
}

extension OnboardingViewController : UITableViewDelegate {
    
}

extension OnboardingViewController : UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        if section == 1 {
            return 4
        }
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Credentials"
        }
        return "Keys"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("InputCell") as! InputCell
                cell.label.text = "Mailaddress"
                cell.textfield.placeholder = "address"
                cell.textfield.keyboardType = UIKeyboardType.EmailAddress
                cell.textfield.autocorrectionType = UITextAutocorrectionType.No
                self.mailaddress = cell.textfield
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("InputCell") as! InputCell
                cell.label.text = "Password"
                cell.textfield.placeholder = "password"
                cell.textfield.secureTextEntry = true
                self.password = cell.textfield
                return cell
                
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! SwitchCell
                cell.label.text = "import private key"
                cell.switcher.addTarget(self, action: #selector(privateKey), forControlEvents: .ValueChanged)
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! SwitchCell
                cell.label.text = "import jakob's pub-key"
                cell.switcher.addTarget(self, action: #selector(jakobKey), forControlEvents: .ValueChanged)
                return cell
            }
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! SwitchCell
                cell.label.text = "import alice's pub-key"
                cell.switcher.addTarget(self, action: #selector(aliceKey), forControlEvents: .ValueChanged)
                return cell
            }
            if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! SwitchCell
                cell.label.text = "import quizer1's pub-key"
                cell.switcher.addTarget(self, action: #selector(quizer1Key), forControlEvents: .ValueChanged)
                return cell
            }
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("AliceKeyCell")!
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
}
