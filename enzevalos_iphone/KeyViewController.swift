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
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

    }

    @IBAction func deleteKey(_ sender: AnyObject) {
        //TODO: REMOVE KEY!
    
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
            if let key = record?.storedKey, key.mailaddress != nil{
                return key.mailaddress!.count
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
                cell.detailTextLabel?.text = record?.keyId
                return cell
            }
            else if toRowType(indexPath) == .fingerprint {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FingerprintCell")!
                cell.detailTextLabel?.numberOfLines = 0
                cell.detailTextLabel?.text = record?.fingerprint
                cell.textLabel?.text = NSLocalizedString("Fingerprint", comment: "Fingerprint of key")
                cell.frame = CGRect(x: cell.frame.minX, y: cell.frame.minY, width: cell.frame.width, height: cell.frame.height+20.5)
                return cell
            }
            else if toRowType(indexPath) == .encryptionType {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EncryptionTypeCell")!
                cell.detailTextLabel?.text = "\(String(describing: record?.cryptoscheme))"
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
                if let discoveryDate = record?.storedKey?.discoveryDate{
                    cell.detailTextLabel?.text = formatter.string(from:  discoveryDate as Date)
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
                cell.textLabel?.text = NSLocalizedString("KeyIsVerified", comment: "The Key is verified. The time when the Key was verified") + "\(String(describing: record?.storedKey?.verifiedDate))"
                return cell
            }
            else if toRowType(indexPath) == .revoked {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RevokedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsRevoked", comment: "The Key is revoked. The time when the Key was revoked") + "NOt SUPPORTED" //TODO Revoke keys
                return cell
            }
        }

            else if toSectionType(indexPath.section) == .addresses {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MailAddressCell")!
            if let addr = record?.addressNames[indexPath.row] { //TODO: Or of key???
                for ourAddr in (record?.addressNames)! {
                    if addr.localizedCaseInsensitiveContains(ourAddr) {
                        cell.accessoryType = UITableViewCellAccessoryType.checkmark
                        break
                    }
                }
            }
            cell.textLabel?.text = record?.addressNames[indexPath.row]
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
        if let key = record?.storedKey {
            var sections = 1
            if let addrs = key.mailaddress, addrs != nil{
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

        if record?.storedKey != nil {
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
        if let key = record?.storedKey, toSectionType(index.section) == .keyDetails {
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
            if row != 0 && key.firstMail != nil {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
            //verified
            if row != 0 && key.isVerified() {
                returnValue = KeyViewRowType(rawValue: returnValue.rawValue + 1)!
                row -= 1
            }
            //TODO revoked
            if row != 0 && key.isExpired() {
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
