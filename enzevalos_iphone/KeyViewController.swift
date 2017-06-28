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
        if let rec = record, rec.key != nil {
            //TODO use EncryptionType from KeyRecord
            keyWrapper = EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(rec.key!)
        }
        tableView.dataSource = self
        tableView.delegate = self

    }

    @IBAction func deleteKey(_ sender: AnyObject) {
        if let key = keyWrapper {
            EnzevalosEncryptionHandler.getEncryption(key.type)?.removeKey(key)
        }
    }

}

extension KeyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if toSectionType(section) == .keyDetails {
            var returnValue = 0
            while(toRowType(IndexPath.init(row: returnValue, section: section)) != .noKey) {
                returnValue += 1
            }
            return returnValue
        }
        if toSectionType(section) == .addresses {
            if let key = keyWrapper, key.mailAddresses != nil {
                return key.mailAddressesInKey!.count
            }
            return 0
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if toSectionType(indexPath.section) == .keyDetails {
            if toRowType(indexPath) == .keyID {
                let cell = tableView.dequeueReusableCell(withIdentifier: "KeyIDCell")!
                cell.textLabel?.text = NSLocalizedString("KeyID", comment: "Identifier of the key")
                cell.detailTextLabel?.text = keyWrapper?.keyID
                return cell
            }
            else if toRowType(indexPath) == .fingerprint {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FingerprintCell")!
                cell.detailTextLabel?.text = keyWrapper?.fingerprint
                cell.textLabel?.text = NSLocalizedString("Fingerprint", comment: "Fingerprint of key")
                return cell
            }
            else if toRowType(indexPath) == .encryptionType {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EncryptionTypeCell")!
                cell.detailTextLabel?.text = keyWrapper?.type.rawValue
                cell.textLabel?.text = NSLocalizedString("EncryptionType", comment: "Type of Encryption")
                return cell
            }
            else if toRowType(indexPath) == .discoveryTime {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveryTimeCell")!
                cell.textLabel?.text = NSLocalizedString("DiscoveryTime", comment: "Time of keydiscovery")
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                if let keyWrapper = keyWrapper {
                    cell.detailTextLabel?.text = formatter.string(from: keyWrapper.discoveryTime as Date)
                }
                return cell
            }
            else if toRowType(indexPath) == .discoveryMail {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveryMailCell")!
                cell.textLabel?.text = "Mail"
                return cell
            }
            else if toRowType(indexPath) == .verified {
                let cell = tableView.dequeueReusableCell(withIdentifier: "VerifiedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsVerified", comment: "The Key is verified. The time when the Key was verified") + "\(String(describing: keyWrapper?.verifyTime))"
                return cell
            }
            else if toRowType(indexPath) == .revoked {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RevokedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsRevoked", comment: "The Key is revoked. The time when the Key was revoked") + "\(String(describing: keyWrapper?.revokeTime))"
                return cell
            }
        }

            else if toSectionType(indexPath.section) == .addresses {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MailAddressCell")!
            if let addr = keyWrapper?.mailAddressesInKey?[indexPath.row] {
                for ourAddr in (keyWrapper?.mailAddresses)! {
                    if addr.localizedCaseInsensitiveContains(ourAddr) {
                        cell.accessoryType = UITableViewCellAccessoryType.checkmark
                        break
                    }
                }
            }
            cell.textLabel?.text = keyWrapper?.mailAddressesInKey?[indexPath.row]
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "VerifiedCell")!
        cell.textLabel?.text = NSLocalizedString("KeyNotFound", comment: "there was no key found. Contact developers")
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("Checkmarks", comment: "Checkmarks")
        }
        return nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if let key = keyWrapper {
            var sections = 1
            if let addrs = key.mailAddresses, addrs != [] {
                sections += 1
            }
            return sections
        }
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if toSectionType(section) == .keyDetails {
            return NSLocalizedString("KeyDetails", comment: "Details of the key")
        }
        if toSectionType(section) == .addresses {
            return NSLocalizedString("KeyAddresses", comment: "Mailaddresses Connected to the key")
        }
        return nil
    }

    func toSectionType(_ sectionNumber: Int) -> KeyViewSectionType {
        var returnValue: KeyViewSectionType = .noKey

        if keyWrapper != nil {
            returnValue = .keyDetails//.KeyID
            //addresses
            if sectionNumber != 0 {
                returnValue = .addresses
            }
        }
        return returnValue
    }

    func toRowType(_ index: IndexPath) -> KeyViewRowType {
        var returnValue: KeyViewRowType = .noKey
        var row = index.row
        if let key = keyWrapper, toSectionType(index.section) == .keyDetails {
            returnValue = .keyID
            //Fingerprint
            if row != 0 {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
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
                returnValue = .noKey
            }
        }
        return returnValue
    }
}

extension KeyViewController: UITableViewDelegate {

}

enum KeyViewSectionType: Int {
    case noKey = 0, keyDetails, addresses
}

enum KeyViewRowType: Int {
    case noKey = 0, keyID, fingerprint, encryptionType, discoveryTime, discoveryMail, verified, revoked
}
