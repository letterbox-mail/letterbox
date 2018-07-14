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
    @IBOutlet weak var copyButton: UIButton!

    var openDate: Date = Date() //used for logging issues [see Logger.log(keyViewClose keyID:String, timevisited: Date)]

    var record: KeyRecord?
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        openDate = Date()
//        Logger.queue.async(flags: .barrier) {
        if let record = self.record, let keyID = record.keyID {
            Logger.log(keyViewOpen: keyID)
        }
//        }
        copyButton.setTitle(NSLocalizedString("copyKey", comment: ""), for: .normal)
        copyButton.setTitle(NSLocalizedString("copied", comment: "the key has been copied to the clipboard"), for: .disabled)
    }

    @IBAction func copyKey(_ sender: AnyObject) {
        guard let record = record, let keyId = record.keyID else {
            return
        }

        let swiftpgp = SwiftPGP()
        if let key = swiftpgp.exportKey(id: keyId, isSecretkey: false, autocrypt: false) {
            UIPasteboard.general.string = key
            copyButton.isEnabled = false
        } else {
            print("Error while getting key")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
//        Logger.queue.async(flags: .barrier) {
        if let record = self.record, let keyID = record.keyID {
            Logger.log(keyViewClose: keyID, secondsOpened: Int(Date().timeIntervalSince(self.openDate)))
        }
//        }
        super.viewDidDisappear(animated)
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
            if let record = record {
                return record.addresses.count
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
                cell.detailTextLabel?.text = record?.keyID
                return cell
            }
            else if toRowType(indexPath) == .fingerprint {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FingerprintCell")!
                cell.detailTextLabel?.numberOfLines = 0
                var result: String = ""
                let characters = Array((record?.fingerprint ?? ""))
                var i = 0
                stride(from: 0, to: characters.count, by: 4).forEach {
                    result += String(characters[$0..<min($0 + 4, characters.count)])
                    if $0 + 4 < characters.count {
                        i = (i + 1) % 3
                        if i == 0 {
                            result += "\n"
                        }
                        else {
                            result += " "
                        }
                    }
                }
                cell.detailTextLabel?.text = result
                cell.textLabel?.text = NSLocalizedString("Fingerprint", comment: "Fingerprint of key")
                return cell
            }
            else if toRowType(indexPath) == .encryptionType {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EncryptionTypeCell")!
                let cryptoscheme: String = record?.cryptoscheme.description ?? ""
                cell.detailTextLabel?.text = cryptoscheme
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
                if let discoveryDate = record?.key?.discoveryDate {
                    cell.detailTextLabel?.text = formatter.string(from: discoveryDate as Date)
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
                cell.textLabel?.text = NSLocalizedString("KeyIsVerified", comment: "The Key is verified. The time when the Key was verified") + "\(String(describing: record?.key?.verifiedDate))"
                return cell
            }
            else if toRowType(indexPath) == .revoked {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RevokedCell")!
                cell.textLabel?.text = NSLocalizedString("KeyIsRevoked", comment: "The Key is revoked. The time when the Key was revoked") + "NOt SUPPORTED"
                //TODO Revoke keys
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
        if let key = record?.key {
            var sections = 1
            if key.mailaddress != nil {
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if toSectionType(indexPath.section) == .keyDetails {
            if toRowType(indexPath) == .fingerprint {
                return 100
            }
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

    func toSectionType(_ sectionNumber: Int) -> KeyViewSectionType {
        var returnValue: KeyViewSectionType = .noKey

        if record?.key != nil {
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
        if let key = record?.key, toSectionType(index.section) == .keyDetails {
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
