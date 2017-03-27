//
//  KeyViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 20.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class KeyViewController: UIViewController {

    @IBOutlet var tableView: UITableView!

    var record: KeyRecord?
    var keyWrapper: KeyWrapper?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let rec = record where rec.key != nil {
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

extension KeyViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if toSectionType(section) == .KeyDetails {
            var returnValue = 0
            while(toRowType(NSIndexPath.init(forRow: returnValue, inSection: section)) != .NoKey) {
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
                let cell = tableView.dequeueReusableCellWithIdentifier("KeyIDCell")!
                cell.textLabel?.text = NSLocalizedString("KeyID", comment: "Identifier of the key")
                cell.detailTextLabel?.text = keyWrapper?.keyID
                return cell
            }
                else if toRowType(indexPath) == .EncryptionType {
                let cell = tableView.dequeueReusableCellWithIdentifier("EncryptionTypeCell")!
                cell.detailTextLabel?.text = keyWrapper?.type.rawValue
                cell.textLabel?.text = NSLocalizedString("EncryptionType", comment: "Type of Encryption")
                return cell
            }
                else if toRowType(indexPath) == .DiscoveryTime {
                let cell = tableView.dequeueReusableCellWithIdentifier("DiscoveryTimeCell")!
                cell.textLabel?.text = NSLocalizedString("DiscoveryTime", comment: "Time of keydiscovery")
                let formatter = NSDateFormatter()
                formatter.locale = NSLocale.currentLocale()
                formatter.dateStyle = .MediumStyle
                formatter.timeStyle = .MediumStyle
                if let keyWrapper = keyWrapper {
                    cell.detailTextLabel?.text = formatter.stringFromDate(keyWrapper.discoveryTime)
                }
                return cell
            }
                else if toRowType(indexPath) == .DiscoveryMail {
                let cell = tableView.dequeueReusableCellWithIdentifier("DiscoveryMailCell")!
                cell.textLabel?.text = "Mail"
                return cell
            }
                else if toRowType(indexPath) == .Verified {
                let cell = tableView.dequeueReusableCellWithIdentifier("VerifiedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsVerified", comment: "The Key is verified. The time when the Key was verified") + "\(keyWrapper?.verifyTime)"
                return cell
            }
                else if toRowType(indexPath) == .Revoked {
                let cell = tableView.dequeueReusableCellWithIdentifier("RevokedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsRevoked", comment: "The Key is revoked. The time when the Key was revoked") + "\(keyWrapper?.revokeTime)"
                return cell
            }
        }

            else if toSectionType(indexPath.section) == .Addresses {
            let cell = tableView.dequeueReusableCellWithIdentifier("MailAddressCell")!
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

        let cell = tableView.dequeueReusableCellWithIdentifier("VerifiedCell")!
        cell.textLabel?.text = NSLocalizedString("KeyNotFound", comment: "there was no key found. Contact developers")
        return cell
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("Checkmarks", comment: "Checkmarks")
        }
        return nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let key = keyWrapper {
            var sections = 1
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

        if keyWrapper != nil {
            returnValue = .KeyDetails//.KeyID
            //addresses
            if sectionNumber != 0 {
                returnValue = .Addresses
            }
        }
        return returnValue
    }

    func toRowType(index: NSIndexPath) -> KeyViewRowType {
        var returnValue: KeyViewRowType = .NoKey
        var row = index.row
        if let key = keyWrapper where toSectionType(index.section) == .KeyDetails {
            returnValue = .KeyID
            //EncryptionType
            if row != 0 {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
            //DiscoveryTime
            if row != 0 {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
            //DiscoveryMail
            if row != 0 && key.discoveryMailUID != nil {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
            //verified
            if row != 0 && key.verified {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
            //revoked
            if row != 0 && key.revoked {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
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

extension KeyViewController: UITableViewDelegate {

}

enum KeyViewSectionType: Int {
    case NoKey = 0, KeyDetails, Addresses
}

enum KeyViewRowType: Int {
    case NoKey = 0, KeyID, EncryptionType, DiscoveryTime, DiscoveryMail, Verified, Revoked
}
