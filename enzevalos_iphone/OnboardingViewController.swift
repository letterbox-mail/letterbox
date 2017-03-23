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
    
    var mailaddress : UITextField? = nil
    var password : UITextField? = nil
    
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        if segue.identifier == "onboarding" {
            for encType in iterateEnum(EncryptionType) {
                let encryption = EnzevalosEncryptionHandler.getEncryption(encType)
                if let enc = encryption {
                    enc.removeAllKeys()
                }
            }
            if pKey {
                //---------------------------------------
                //Import private Key BEGIN
                
                 let path = NSBundle.mainBundle().pathForResource("alice2005-private", ofType: "gpg")        //<---- Schlüsseldatei
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
            if let addr = mailaddress?.text where addr != "" {
                //if addr.componentsSeparatedByString("@")[1] != "web.de" {
                // naechste view
                //}
                Attribute.attributeValues[Attribute.UserAddr] = addr
                Attribute.attributeValues[Attribute.Accountname] = addr.componentsSeparatedByString("@")[0]
            }
            if let pw = password?.text where pw != "" {
                Attribute.attributeValues[Attribute.UserPW] = pw
            }
        }
    }
    
    func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
        var i = 0
        return anyGenerator {
            let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
            return next.hashValue == i++ ? next : nil
        }
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
            return 3
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
                self.mailaddress = cell.textfield
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("InputCell") as! InputCell
                cell.label.text = "Password"
                cell.textfield.placeholder = "password"
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
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("AliceKeyCell")!
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
}
