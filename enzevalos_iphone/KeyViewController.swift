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
    
    @IBAction func deleteKey(sender: AnyObject) {
        if let key = keyWrapper {
            EnzevalosEncryptionHandler.getEncryption(key.type)?.removeKey(key)
        }
    }
    
}

extension KeyViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if toSectionType(section) == .KeyDetails {
            var returnValue = 0
            while(toRowType(NSIndexPath.init(forRow: returnValue, inSection: section)) != .NoKey){
                returnValue += 1
            }
            return returnValue
        }
        if toSectionType(section) == .Addresses {
            if let key = keyWrapper where key.mailAddresses != nil {
                return key.mailAddressesInKey!.count
            }
            return 0
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if toSectionType(indexPath.section) == .KeyDetails {
            if toRowType(indexPath) == .KeyID {
                var cell = tableView.dequeueReusableCellWithIdentifier("KeyIDCell")!
                cell.textLabel?.text = NSLocalizedString("KeyID", comment: "Identifier of the key")
                cell.detailTextLabel?.text = keyWrapper?.keyID
                return cell
            }
            else if toRowType(indexPath) == .EncryptionType {
                var cell = tableView.dequeueReusableCellWithIdentifier("EncryptionTypeCell")!
                cell.detailTextLabel?.text = keyWrapper?.type.rawValue
                cell.textLabel?.text = NSLocalizedString("EncryptionType", comment: "Type of Encryption")
                return cell
            }
            else if toRowType(indexPath) == .DiscoveryTime {
                var cell = tableView.dequeueReusableCellWithIdentifier("DiscoveryTimeCell")!
                cell.textLabel?.text = NSLocalizedString("DiscoveryTime", comment: "Time of keydiscovery")
                cell.detailTextLabel?.text = keyWrapper?.discoveryTime.description
                return cell
            }
            else if toRowType(indexPath) == .DiscoveryMail {
                var cell = tableView.dequeueReusableCellWithIdentifier("DiscoveryMailCell")!
                cell.textLabel?.text = "Mail"
                return cell
            }
            else if toRowType(indexPath) == .Verified {
                var cell = tableView.dequeueReusableCellWithIdentifier("VerifiedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsVerified", comment: "The Key is verified. The time when the Key was verified")+"\(keyWrapper?.verifyTime)"
                return cell
            }
            else if toRowType(indexPath) == .Revoked {
                var cell = tableView.dequeueReusableCellWithIdentifier("RevokedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsRevoked", comment: "The Key is revoked. The time when the Key was revoked")+"\(keyWrapper?.revokeTime)"
                return cell
            }
        }
        
        else if toSectionType(indexPath.section) == .Addresses {
            var cell = tableView.dequeueReusableCellWithIdentifier("MailAddressCell")!
            if let addr = keyWrapper?.mailAddressesInKey?[indexPath.row] {
                for ourAddr in (keyWrapper?.mailAddresses)! {
                    if addr.containsString(ourAddr) {
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                        break
                    }
                }
            }
            cell.textLabel?.text = keyWrapper?.mailAddressesInKey?[indexPath.row]
            return cell
        }
        
        var cell = tableView.dequeueReusableCellWithIdentifier("VerifiedCell")!
        cell.textLabel?.text = NSLocalizedString("KeyNotFound", comment: "there was no key found. Contact developers")
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let key = keyWrapper {
            var sections = 1
            /*if key.discoveryMailUID != nil {
                sections += 1
            }
            if key.verified {
                sections += 1
            }
            if key.revoked {
                sections += 1
            }*/
            if let addrs = key.mailAddresses where addrs != [] {
                sections += 1
            }
            return sections
        }
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if toSectionType(section) == .KeyDetails {
            return NSLocalizedString("KeyDetails", comment: "Details of the key")
        }
        if toSectionType(section) == .Addresses {
            return NSLocalizedString("KeyAddresses", comment: "Mailaddresses Connected to the key")
        }
        return nil
    }
    
    func toSectionType(sectionNumber: Int) -> KeyViewSectionType {
        var returnValue: KeyViewSectionType = .NoKey
        var section = sectionNumber
        
        if let key = keyWrapper {
            returnValue = .KeyDetails//.KeyID
            /*//keyID
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
            }*/
            //addresses
            if section != 0 {
                returnValue = .Addresses
            }
        }
        return returnValue
    }
    
    func toRowType(index: NSIndexPath) -> KeyViewRowType {
        var returnValue : KeyViewRowType = .NoKey
        var row = index.row
        if let key = keyWrapper where toSectionType(index.section) == .KeyDetails {
            returnValue = .KeyID
            //EncryptionType
            if row != 0 {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue+1)!
                row -= 1
            }
            //DiscoveryTime
            if row != 0 {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue+1)!
                row -= 1
            }
            //DiscoveryMail
            if row != 0 && key.discoveryMailUID != nil {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue+1)!
                row -= 1
            }
            //verified
            if row != 0 && key.verified {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue+1)!
                row -= 1
            }
            //revoked
            if row != 0 && key.revoked {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue+1)!
                row -= 1
            }
            //too much rows
            if row != 0 {
                returnValue = .NoKey
            }
        }
        return returnValue
    }
}

extension KeyViewController : UITableViewDelegate {
    
}

enum KeyViewSectionType : Int {
    case NoKey = 0, KeyDetails, Addresses
}

enum KeyViewRowType : Int {
    case NoKey = 0, KeyID, EncryptionType, DiscoveryTime, DiscoveryMail, Verified, Revoked
}
