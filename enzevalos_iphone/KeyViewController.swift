//
//  KeyViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 20.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class KeyViewController : UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var record: KeyRecord?
    var keyWrapper: KeyWrapper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let rec = record where rec.key != nil{
            //TODO use EncryptionType from KeyRecord
            keyWrapper = EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(rec.key!)
        }
        tableView.dataSource = self
        tableView.delegate = self
        
    }
    
    
}

extension KeyViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if toSectionType(section) == .Addresses {
            if let key = keyWrapper where key.mailAddresses != nil {
                return key.mailAddresses!.count
            }
            return 0
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if toSectionType(indexPath.section) == .KeyID {
            var cell = tableView.dequeueReusableCellWithIdentifier("KeyIDCell")!
            cell.textLabel?.text = keyWrapper?.keyID
            return cell
        }
        if toSectionType(indexPath.section) == .EncryptionType {
            var cell = tableView.dequeueReusableCellWithIdentifier("EncryptionTypeCell")!
            cell.textLabel?.text = keyWrapper?.type.rawValue
            return cell
        }
        if toSectionType(indexPath.section) == .DiscoveryTime {
            var cell = tableView.dequeueReusableCellWithIdentifier("DiscoveryTimeCell")!
            cell.textLabel?.text = keyWrapper?.discoveryTime.description
        }
        
        
        var cell = tableView.dequeueReusableCellWithIdentifier("VerifiedCell")!
        cell.textLabel?.text = NSLocalizedString("KeyNotFound", comment: "there was no key found in the backend")
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let key = keyWrapper {
            var sections = 3
            if key.discoveryMailUID != nil {
                sections += 1
            }
            if key.verified {
                sections += 1
            }
            if key.revoked {
                sections += 1
            }
            if let addrs = key.mailAddresses where addrs != [] {
                sections += 1
            }
            return sections
        }
        return 1
    }
    
    func toSectionType(sectionNumber: Int) -> KeyViewSectionType {
        var returnValue: KeyViewSectionType = .NoKey
        var section = sectionNumber
        
        if let key = keyWrapper {
            returnValue = .KeyID
            //keyID
            if section != 0 {
                returnValue = KeyViewSectionType(rawValue: returnValue.rawValue+1)!
                section -= 1
            }
            //EncryptionType
            if section != 0 {
                returnValue = KeyViewSectionType(rawValue: returnValue.rawValue+1)!
                section -= 1
            }
            //DiscoveryTime
            if section != 0 {
                returnValue = KeyViewSectionType(rawValue: returnValue.rawValue+1)!
                section -= 1
            }
            //DiscoveryMail
            if section != 0 && key.discoveryMailUID != nil {
                returnValue = KeyViewSectionType(rawValue: returnValue.rawValue+1)!
                section -= 1
            }
            //verified
            if section != 0 && key.verified {
                returnValue = KeyViewSectionType(rawValue: returnValue.rawValue+1)!
                section -= 1
            }
            //revoked
            if section != 0 && key.revoked {
                returnValue = KeyViewSectionType(rawValue: returnValue.rawValue+1)!
                section -= 1
            }
            //addresses
            if section != 0 {
                returnValue = .Addresses
            }
        }
        return returnValue
    }
}

extension KeyViewController : UITableViewDelegate {
    
}

enum KeyViewSectionType : Int {
    case NoKey = 0, KeyID, EncryptionType, DiscoveryTime, DiscoveryMail, Verified, Revoked, Addresses
}
