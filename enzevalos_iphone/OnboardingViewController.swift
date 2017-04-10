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
    
    @IBAction func privateKey(_ sender: AnyObject, forEvent event: UIEvent) {
        pKey = !pKey
    }
    @IBAction func jakobKey(_ sender: AnyObject, forEvent event: UIEvent) {
        jKey = !jKey
    }
    @IBAction func aliceKey(_ sender: AnyObject, forEvent event: UIEvent) {
        aKey = !aKey
    }
    @IBAction func quizer1Key(_ sender: AnyObject, forEvent event: UIEvent) {
        q1Key = !q1Key
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "onboarding" {
            var mAddr = ""
            var mPw = ""
            if let addr = mailaddress?.text, addr != "" {
                //if addr.componentsSeparatedByString("@")[1] != "web.de" {
                // naechste view
                //}
                /*let guessedUserName = addr.componentsSeparatedByString("@")[0]
                 UserManager.storeUserValue(addr, attribute: Attribute.UserAddr)//Attribute.attributeValues[Attribute.UserAddr] = addr
                 UserManager.storeUserValue(guessedUserName, attribute: Attribute.UserName)*/
                mAddr = addr
            }
            if let pw = password?.text, pw != "" {
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
                
                 var path = Bundle.main.path(forResource: "alice2005-private", ofType: "gpg")        //<---- Schlüsseldatei
                 if mAddr.contains("@") && mAddr.components(separatedBy: "@")[1] == Provider.ENZEVALOS.rawValue {
                        path = Bundle.main.path(forResource: "quizer1-private", ofType: "asc")
                 }
                let pgp = ObjectivePGP.init()
                 pgp.importKeys(fromFile: path!, allowDuplicates: false)
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
                
                 let path = Bundle.main.path(forResource: "JakobBode", ofType: "asc")               //<---- Schlüsseldatei
                 let pgp = ObjectivePGP.init()
                 pgp.importKeys(fromFile: path!, allowDuplicates: false)
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
                
                 let path = Bundle.main.path(forResource: "alice2005-public", ofType: "gpg")               //<---- Schlüsseldatei
                 let pgp = ObjectivePGP.init()
                 pgp.importKeys(fromFile: path!, allowDuplicates: false)
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
                
                let path = Bundle.main.path(forResource: "quizer1-public", ofType: "asc")               //<---- Schlüsseldatei
                let pgp = ObjectivePGP.init()
                pgp.importKeys(fromFile: path!, allowDuplicates: false)
                let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
                do {
                    let data = try pgp.keys[0].export()
                    enc?.addKey(data, forMailAddresses: ["quizer1@enzevalos.de"])                           //<---- Emailadresse
                }
                catch _ {}
                
                //Import public key END
                //---------------------------------------
            }
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
    }
    
    func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) { UnsafeRawPointer($0).load(as: T.self) }
            i += 1
            return next.hashValue == i-1 ? next : nil
        }
    }
    
    func setGuessValues(_ mailAddress: String, pw: String) {
        if mailAddress != "" {
            let guessedUserName = mailAddress.components(separatedBy: "@")[0]
            let provider = mailAddress.components(separatedBy: "@")[1]
            UserManager.storeUserValue(mailAddress as AnyObject?, attribute: Attribute.userAddr)//Attribute.attributeValues[Attribute.UserAddr] = addr
            UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.userName)
            if provider == Provider.FU.rawValue {
                Providers.setValues(Provider.FU)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.accountname)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.userName)
            }
            if provider == Provider.ZEDAT.rawValue {
                Providers.setValues(Provider.ZEDAT)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.accountname)
                UserManager.storeUserValue("jakobsbode" as AnyObject?, attribute: Attribute.userName)
            }
            if provider == Provider.ENZEVALOS.rawValue {
                Providers.setValues(Provider.ENZEVALOS)
                UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.accountname)
                UserManager.storeUserValue(guessedUserName as AnyObject?, attribute: Attribute.userName)
            }
        }
        if pw != "" {
            UserManager.storeUserValue(pw as AnyObject?, attribute: Attribute.userPW)
        }
        smtpCheckDone = false
        imapCheckDone = false
        /*AppDelegate.getAppDelegate().mailHandler.checkSMTP(SMTPCompletion)
        AppDelegate.getAppDelegate().mailHandler.checkIMAP(IMAPCompletion)
        while (!imapCheckDone || !smtpCheckDone) {
            
        }*/
        print("checks ", imapCheck, smtpCheck)
    }
    
    private func SMTPCompletion(_ error: NSError?) {
        if error == nil {
            smtpCheck = true
        }
        smtpCheckDone = true
    }
    
    private func IMAPCompletion(_ error: NSError?) {
        if error == nil {
            imapCheck = true
        }
        imapCheckDone = true
    }
    
}

extension OnboardingViewController : UITableViewDelegate {
    
}

extension OnboardingViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        if section == 1 {
            return 4
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Credentials"
        }
        return "Keys"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell") as! InputCell
                cell.label.text = "Mailaddress"
                cell.textfield.placeholder = "address"
                cell.textfield.keyboardType = UIKeyboardType.emailAddress
                cell.textfield.autocorrectionType = UITextAutocorrectionType.no
                self.mailaddress = cell.textfield
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell") as! InputCell
                cell.label.text = "Password"
                cell.textfield.placeholder = "password"
                cell.textfield.isSecureTextEntry = true
                self.password = cell.textfield
                return cell
                
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchCell
                cell.label.text = "import private key"
                cell.switcher.addTarget(self, action: #selector(privateKey), for: .valueChanged)
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchCell
                cell.label.text = "import jakob's pub-key"
                cell.switcher.addTarget(self, action: #selector(jakobKey), for: .valueChanged)
                return cell
            }
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchCell
                cell.label.text = "import alice's pub-key"
                cell.switcher.addTarget(self, action: #selector(aliceKey), for: .valueChanged)
                return cell
            }
            if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchCell
                cell.label.text = "import quizer1's pub-key"
                cell.switcher.addTarget(self, action: #selector(quizer1Key), for: .valueChanged)
                return cell
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "AliceKeyCell")!
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}
