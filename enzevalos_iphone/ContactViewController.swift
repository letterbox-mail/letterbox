//
//  ContactViewController.swift
//  enzevalos_iphone
//
//  Created by Joscha on 22.12.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import UIKit
import Contacts
import ContactsUI

class ContactViewController: UIViewController {
    var keyRecord: KeyRecord? = nil
    var hasKey: Bool = false
    var highlightEmail: String? = nil
    private var uiContact: CNContact? = nil
    private var vc: CNContactViewController? = nil
    fileprivate var otherRecords: [KeyRecord]? = nil
    var isUser: Bool = false

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0

        self.navigationController?.navigationBar.barTintColor = ThemeManager.defaultColor
        if let con = keyRecord {
            hasKey = EnzevalosEncryptionHandler.hasKey(con.ezContact)

            let myAddress = UserManager.loadUserValue(Attribute.userAddr) as! String
            if con.addresses.contains(where: { $0.mailAddress.lowercased() == myAddress
            }) {
                self.title = NSLocalizedString("you", comment: "String decribing this as the account of the user")
                isUser = true
            } else {
                self.title = con.name
            }
//            self.title = CNContactFormatter.stringFromContact(con.ezContact.cnContact, style: .FullName)

            prepareContactSheet()

            otherRecords = con.ezContact.records.filter({ $0 != keyRecord })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if let row = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: row, animated: false)
        }
        navigationController?.toolbar.isHidden = false
    }

    func prepareContactSheet() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let identifier = keyRecord?.cnContact?.identifier
                if let id = identifier {
                    uiContact = try AppDelegate.getAppDelegate().contactStore.unifiedContact(withIdentifier: id, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
                }
            } catch {
                //contact doesn't exist or we don't have authorization
                //TODO: handle missing authorization
            }
        }
        if let conUI = uiContact {
            let infoButton = UIButton(type: .infoLight)
            vc = CNContactViewController(for: conUI)
//            vc!.contactStore = AppDelegate.getAppDelegate().contactStore // nötig?
            infoButton.addTarget(self, action: #selector(ContactViewController.showContact), for: .touchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        } else {
            let addButton = UIButton(type: .contactAdd)
            vc = CNContactViewController(forNewContact: keyRecord!.ezContact.newCnContact)
//            vc!.contactStore = AppDelegate.getAppDelegate().contactStore // nötig?
            vc!.delegate = self
            addButton.addTarget(self, action: #selector(ContactViewController.showContact), for: .touchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        }
    }

    func drawStatusCircle() -> UIImage? {
        guard keyRecord != nil else {
            return nil
        }
        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, false, 2) //try 200 here

        let context = UIGraphicsGetCurrentContext()

        // Clip context to a circle
        let path = CGPath(ellipseIn: myBounds, transform: nil);
        context!.addPath(path);
        context!.clip();

        // Fill background of context
        var bgColor: CGColor = ThemeManager.defaultColor.cgColor
        if keyRecord!.isVerified {
            bgColor = Theme.very_strong_security_indicator.encryptedVerifiedMessageColor.cgColor
        } else if !keyRecord!.hasKey {
            bgColor = Theme.very_strong_security_indicator.uncryptedMessageColor.cgColor
        }
        context!.setFillColor(bgColor)
        context!.fill(CGRect(x: 0, y: 0, width: myBounds.size.width, height: myBounds.size.height));

        let iconSize = CGFloat(50)
        let frame = CGRect(x: myBounds.size.width / 2 - iconSize / 2, y: myBounds.size.height / 2 - iconSize / 2, width: iconSize, height: iconSize)

        if keyRecord!.hasKey {
            IconsStyleKit.drawLetter(frame: frame, fillBackground: true)
        } else if keyRecord!.isVerified {
            IconsStyleKit.drawLetter(frame: frame, color: UIColor.white)
        } else {
            IconsStyleKit.drawPostcard(frame: frame, resizing: .aspectFit, color: UIColor.white)
        }

        let img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img
    }

    func showContact() {
        self.navigationController?.pushViewController(vc!, animated: true)
        navigationController?.toolbar.isHidden = true
    }

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        _ = self.navigationController?.popViewController(animated: true)
        prepareContactSheet()
    }

    @IBAction func actionButton(_ sender: AnyObject) {
        guard let sender = sender as? UIButton else {
            return
        }

        if sender.titleLabel?.text == NSLocalizedString("toEncrypted", comment: "switch to encrypted") {
            let myPath = IndexPath(row: 1, section: 0)
            tableView.selectRow(at: myPath, animated: false, scrollPosition: .none)
            performSegue(withIdentifier: "otherRecord", sender: nil)
        } else if sender.titleLabel?.text == NSLocalizedString("invite", comment: "invite contact") {
            let mail = EphemeralMail(to: NSSet.init(array: keyRecord!.addresses), cc: NSSet.init(), bcc: NSSet.init(), date: Date(), subject: NSLocalizedString("inviteSubject", comment: ""), body: NSLocalizedString("inviteText", comment: ""), uid: 0, predecessor: nil)
            performSegue(withIdentifier: "newMail", sender: mail)
        } else if sender.titleLabel?.text == NSLocalizedString("verifyNow", comment: "Verify now") && keyRecord!.key != nil {
            performSegue(withIdentifier: "verifyQRCode", sender: EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(keyRecord!.key!)?.fingerprint)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newMail" {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController {
                if let mail = sender as? EphemeralMail {
                    controller.prefilledMail = mail
                } else {
                    let indexPath = tableView.indexPathForSelectedRow
                    if indexPath!.row < keyRecord!.ezContact.getMailAddresses().count {
                        controller.toField = keyRecord!.ezContact.getMailAddresses()[indexPath!.row].mailAddress
                    }
                }
            }
        } else if segue.identifier == "mailList" {
            let DestinationViewController: ListViewController = segue.destination as! ListViewController
            DestinationViewController.contact = keyRecord
        } else if segue.identifier == "otherRecord" {
            let DestinationViewController: ContactViewController = segue.destination as! ContactViewController
            let indexPath = tableView.indexPathForSelectedRow
            if let r = otherRecords {
                if let indexPath = indexPath, indexPath.section == 3 && !(keyRecord?.hasKey ?? false) || indexPath.section == 4 && (keyRecord?.hasKey ?? false) {
                    let destinationRecord = r[indexPath.row]
                    DestinationViewController.keyRecord = destinationRecord
                } else {
                    DestinationViewController.keyRecord = otherRecords!.first
                }
            }
        } else if segue.identifier == "keyView" {
            let destinationViewController: KeyViewController = segue.destination as! KeyViewController
            destinationViewController.record = keyRecord
        } else if segue.identifier == "verifyQRCode" {
            if let DestinationViewController = segue.destination as? QRScannerView {
                DestinationViewController.fingerprint = EnzevalosEncryptionHandler.getEncryption(.PGP)!.getKey(keyRecord!.key!)!.fingerprint
                DestinationViewController.callback = verifySuccessfull
            }
        }
    }

    func verifySuccessfull() {
//        EnzevalosEncryptionHandler.getEncryption(.PGP)!.getKey(keyRecord!.key!)!.verified = true // TODO @Jakob: key is not writable
        tableView.reloadData()
    }
}

extension ContactViewController: CNContactViewControllerDelegate {

}

extension ContactViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if keyRecord != nil {
            switch indexPath.section {
            case 0:
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ContactViewCell") as! ContactViewCell
                    cell.contactImage.image = keyRecord!.ezContact.getImageOrDefault()
                    cell.contactImage.layer.cornerRadius = cell.contactImage.frame.height / 2
                    cell.contactImage.clipsToBounds = true
                    cell.iconImage.image = drawStatusCircle()
                    if isUser {
                        cell.contactStatus.text = NSLocalizedString("thisIsYou", comment: "This contact is the user")
                    } else if keyRecord!.isVerified {
                        cell.contactStatus.text = NSLocalizedString("Verified", comment: "Contact is verified")
                    } else if keyRecord!.hasKey {
                        cell.contactStatus.text = NSLocalizedString("notVerified", comment: "Contact is not verified jet")
                    } else if (otherRecords?.filter({ $0.hasKey }).count ?? 0) > 0 {
                        cell.contactStatus.text = NSLocalizedString("otherEncryption", comment: "Contact is using encryption, this is the unsecure collection")
                    } else if hasKey {
                        cell.contactStatus.text = NSLocalizedString("hasKeyButNoMail", comment: "We have a key to this contact but haven't received an encrypted mail jet")
                    } else {
                        cell.contactStatus.text = NSLocalizedString("noEncryption", comment: "Contact is not jet using encryption")
                    }
                    return cell
                } else if indexPath.row == 1 {
                    if isUser && keyRecord!.hasKey {
                        let qrCodeCell = tableView.dequeueReusableCell(withIdentifier: "QRCodeCell", for: indexPath) as! QRCodeCell
                        let qrCode = QRCode.generate(input: "OPENPGP4FPR:\(EnzevalosEncryptionHandler.getEncryption(.PGP)!.getKey(keyRecord!.key!)!.fingerprint)")

                        let scaleX = qrCodeCell.qrCode.frame.size.width / qrCode.extent.size.width
                        let scaleY = qrCodeCell.qrCode.frame.size.height / qrCode.extent.size.height

                        qrCodeCell.label.text = NSLocalizedString("yourFingerprint", comment: "")
                        qrCodeCell.qrCode.image = UIImage(ciImage: qrCode.applying(CGAffineTransform(scaleX: scaleX, y: scaleY)))

                        return qrCodeCell
                    } else {
                        let actionCell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! ActionCell
                        if keyRecord!.hasKey {
                            actionCell.Button.setTitle(NSLocalizedString("verifyNow", comment: "Verify now"), for: UIControlState())
                        } else if (otherRecords?.filter({ $0.hasKey }).count ?? 0) > 0 {
                            actionCell.Button.setTitle(NSLocalizedString("toEncrypted", comment: "switch to encrypted"), for: UIControlState())
                        } else if hasKey {
                            actionCell.Button.setTitle(NSLocalizedString("verifyNow", comment: "Verify now"), for: UIControlState())
                        } else {
                            actionCell.Button.setTitle(NSLocalizedString("invite", comment: "Invide contact to use encryption"), for: UIControlState())
                        }
                        return actionCell
                    }
                }
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "MailCell") as! MailCell
                if let address = keyRecord?.ezContact.getMailAddresses()[indexPath.item].mailAddress {
                    if let highlightEmail = highlightEmail, highlightEmail.contains(address) {
                        cell.detailLabel.textColor = view.tintColor
                        cell.titleLabel.textColor = view.tintColor
                    }
                    cell.detailLabel.text = address
                }
                if let label = keyRecord?.ezContact.getMailAddresses()[indexPath.item].label.label {
                    cell.titleLabel.text = CNLabeledValue<NSString>.localizedString(forLabel: label)
                } else {
                    cell.titleLabel.text = ""
                }

                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "AllMails", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("allMessages", comment: "show all messages")
                return cell
            case 3 where (keyRecord?.hasKey) ?? false:
                let cell = tableView.dequeueReusableCell(withIdentifier: "KeyCell", for: indexPath)
                cell.textLabel?.text = NSLocalizedString("Details", comment: "Details")
                return cell
            case 3 where !((keyRecord?.hasKey) ?? false):
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordCell
                if let r = otherRecords {
                    if let key = r[indexPath.row].key, let time = EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(key)?.discoveryTime {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale.current
                        dateFormatter.dateStyle = .medium
                        cell.dateLabel.text = dateFormatter.string(from: time)
                        cell.iconImage.image = IconsStyleKit.imageOfLetter
                    } else {
                        cell.dateLabel.text = ""
                        cell.iconImage.image = IconsStyleKit.imageOfPostcard
                    }
                    cell.label.text = r[indexPath.row].addresses.first?.mailAddress
                }
                return cell
            case 4 where !((keyRecord?.hasKey) ?? false):
                let cell = tableView.dequeueReusableCell(withIdentifier: "KeyCell", for: indexPath)
                cell.textLabel?.text = "abc"
                return cell
            case 4 where (keyRecord?.hasKey) ?? false:
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordCell
                if let r = otherRecords {
                    if let key = r[indexPath.row].key, let time = EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(key)?.discoveryTime {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale.current
                        dateFormatter.dateStyle = .medium
                        cell.dateLabel.text = dateFormatter.string(from: time)
                        cell.iconImage.image = IconsStyleKit.imageOfLetter
                    } else {
                        cell.dateLabel.text = ""
                        cell.iconImage.image = IconsStyleKit.imageOfPostcard
                    }
                    cell.label.text = r[indexPath.row].addresses.first?.mailAddress
                }
                return cell
            default:
                break
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: "MailCell", for: indexPath)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 3
        if (keyRecord?.ezContact.records.count ?? 0) > 1 {
            sections += 1
        }
        if let hasKey = keyRecord?.hasKey, hasKey {
            sections += 1
        }
        return sections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let record = keyRecord {
            switch section {
            case 0:
                if !record.isVerified {
                    return 2
                }
            case 1:
                return record.ezContact.getMailAddresses().count
            case 3 where !((keyRecord?.hasKey) ?? false):
                if let rec = otherRecords {
                    return rec.count
                }
                return 0
            case 4 where (keyRecord?.hasKey) ?? false:
                if let rec = otherRecords {
                    return rec.count
                }
                return 0
            default:
                break
            }
        }
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return NSLocalizedString("connectedAddresses", comment: "All addresses connected to this keyrecord")
        case 3 where !((keyRecord?.hasKey) ?? false):
            return NSLocalizedString("otherRecords", comment: "Other records of this contact")
        case 4 where (keyRecord?.hasKey) ?? false:
            return NSLocalizedString("otherRecords", comment: "Other records of this contact")
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
//            return "Mit diesem Kontakt kommunizieren Sie zu 93% verschlüsselt und im Durchschnitt 2,3 x pro Woche." // Nur ein Test
        }
        return nil
    }
}

extension ContactViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if indexPath.section == 1 {
            UIPasteboard.general.string = keyRecord!.ezContact.getMailAddresses()[indexPath.row].mailAddress
        }
    }
}

extension ContactViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push where (tableView.indexPathForSelectedRow?.section == 4 && ((keyRecord?.hasKey) ?? false) || tableView.indexPathForSelectedRow?.section == 3 && !((keyRecord?.hasKey) ?? false)) || tableView.indexPathForSelectedRow?.section == 0:
            return FlipTransition()
        default:
            return nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

extension ContactViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
