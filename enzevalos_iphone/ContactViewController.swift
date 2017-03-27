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
    var highlightEmail: String? = nil
    private var uiContact: CNContact? = nil
    private var vc: CNContactViewController? = nil
    private var otherRecords: [KeyRecord]? = nil

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
            self.title = con.name
//            self.title = CNContactFormatter.stringFromContact(con.ezContact.cnContact, style: .FullName)

            prepareContactSheet()

            otherRecords = con.ezContact.records.filter({ $0 != keyRecord })
        }
    }

    override func viewWillAppear(animated: Bool) {
        if let row = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(row, animated: false)
        }
    }

    func prepareContactSheet() {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                uiContact = try AppDelegate.getAppDelegate().contactStore.unifiedContactWithIdentifier(keyRecord!.cnContact!.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            } catch {
                //contact doesn't exist or we don't have authorization
                //TODO: handle missing authorization
            }
        }
        if let conUI = uiContact {
            let infoButton = UIButton(type: .InfoLight)
            vc = CNContactViewController(forContact: conUI)
            vc!.contactStore = AppDelegate.getAppDelegate().contactStore // nötig?
            infoButton.addTarget(self, action: #selector(ContactViewController.showContact), forControlEvents: .TouchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        } else {
            let addButton = UIButton(type: .ContactAdd)
            vc = CNContactViewController(forNewContact: keyRecord!.cnContact)
            vc!.contactStore = AppDelegate.getAppDelegate().contactStore // nötig?
            vc!.delegate = self
            addButton.addTarget(self, action: #selector(ContactViewController.showContact), forControlEvents: .TouchUpInside)
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
        let path = CGPathCreateWithEllipseInRect(myBounds, nil);
        CGContextAddPath(context!, path);
        CGContextClip(context!);

        // Fill background of context
        var bgColor: CGColor = ThemeManager.defaultColor.CGColor
        if keyRecord!.isVerified {
            bgColor = Theme.Very_strong_security_indicator.encryptedVerifiedMessageColor.CGColor
        } else if !keyRecord!.hasKey {
            bgColor = Theme.Very_strong_security_indicator.uncryptedMessageColor.CGColor
        }
        CGContextSetFillColorWithColor(context!, bgColor)
        CGContextFillRect(context!, CGRectMake(0, 0, myBounds.size.width, myBounds.size.height));

        let iconSize = CGFloat(50)
        let frame = CGRectMake(myBounds.size.width / 2 - iconSize / 2, myBounds.size.height / 2 - iconSize / 2, iconSize, iconSize)

        if keyRecord!.hasKey {
            IconsStyleKit.drawLetter(frame: frame, fillBackground: true)
        } else if keyRecord!.isVerified {
            IconsStyleKit.drawLetter(frame: frame, color: UIColor.whiteColor())
        } else {
            IconsStyleKit.drawPostcard(frame: frame, resizing: .AspectFit, color: UIColor.whiteColor())
        }

        let img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img
    }

    func showContact() {
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
        self.navigationController?.popViewControllerAnimated(true)
        prepareContactSheet()
    }

    @IBAction func actionButton(sender: AnyObject) {
        if (sender as? UIButton)?.titleLabel?.text == NSLocalizedString("toEncrypted", comment: "switch to encrypted") {
            let myPath = NSIndexPath(forRow: 1, inSection: 0)
            tableView.selectRowAtIndexPath(myPath, animated: false, scrollPosition: .None)
            performSegueWithIdentifier("otherRecord", sender: nil)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "newMail" {
            let navigationController = segue.destinationViewController as? UINavigationController
            let controller = navigationController?.topViewController as? SendViewController
            let indexPath = tableView.indexPathForSelectedRow
            if controller != nil {
                // TODO: add address to SendView
                if indexPath!.row < keyRecord!.ezContact.getMailAddresses().count {
                    controller!.toField = keyRecord!.ezContact.getMailAddresses()[indexPath!.row].mailAddress
                }
            }
        } else if segue.identifier == "mailList" {
            let DestinationViewController: ListViewController = segue.destinationViewController as! ListViewController
            DestinationViewController.contact = keyRecord
        } else if segue.identifier == "otherRecord" {
            let DestinationViewController: ContactViewController = segue.destinationViewController as! ContactViewController
            let indexPath = tableView.indexPathForSelectedRow
            if let r = otherRecords {
                if let indexPath = indexPath where indexPath.section == 3 && !(keyRecord?.hasKey ?? false) || indexPath.section == 4 && (keyRecord?.hasKey ?? false) {
                    let destinationRecord = r[indexPath.row]
                    DestinationViewController.keyRecord = destinationRecord
                } else {
                    DestinationViewController.keyRecord = otherRecords!.first
                }
            }
        } else if segue.identifier == "keyView" {
            let destinationViewController: KeyViewController = segue.destinationViewController as! KeyViewController
            destinationViewController.record = keyRecord
        }
    }
}

extension ContactViewController: CNContactViewControllerDelegate {

}

extension ContactViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if keyRecord != nil {
            switch indexPath.section {
            case 0:
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("ContactViewCell") as! ContactViewCell
                    cell.contactImage.image = keyRecord!.cnContact!.getImageOrDefault()
                    cell.contactImage.layer.cornerRadius = cell.contactImage.frame.height / 2
                    cell.contactImage.clipsToBounds = true
                    cell.iconImage.image = drawStatusCircle()
                    if keyRecord!.isVerified {
                        cell.contactStatus.text = NSLocalizedString("Verified", comment: "Contact is verified")
                    } else if keyRecord!.hasKey {
                        cell.contactStatus.text = NSLocalizedString("notVerified", comment: "Contact is not verified jet")
                    } else if otherRecords?.filter({ $0.hasKey }).count > 0 {
                        cell.contactStatus.text = NSLocalizedString("otherEncryption", comment: "Contact is using encryption, this is the unsecure collection")
                    } else {
                        cell.contactStatus.text = NSLocalizedString("noEncryption", comment: "Contact is not jet using encryption")
                    }
                    return cell
                } else if indexPath.row == 1 {
                    let actionCell = tableView.dequeueReusableCellWithIdentifier("ActionCell", forIndexPath: indexPath) as! ActionCell
                    if keyRecord!.hasKey {
                        actionCell.Button.setTitle(NSLocalizedString("verifyNow", comment: "Verify now"), forState: .Normal)
                    } else if otherRecords?.filter({ $0.hasKey }).count > 0 {
                        actionCell.Button.setTitle(NSLocalizedString("toEncrypted", comment: "switch to encrypted"), forState: .Normal)
                    } else {
                        actionCell.Button.setTitle(NSLocalizedString("invite", comment: "Invide contact to use encryption"), forState: .Normal)
                    }
                    return actionCell
                }
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("MailCell") as! MailCell
                if let address = keyRecord?.ezContact.getMailAddresses()[indexPath.item].mailAddress {
                    if let highlightEmail = highlightEmail where highlightEmail.containsString(address) {
                        cell.detailLabel.textColor = view.tintColor
                        cell.titleLabel.textColor = view.tintColor
                    }
                    cell.detailLabel.text = address
                }
                if let label = keyRecord?.ezContact.getMailAddresses()[indexPath.item].label.label {
                    cell.titleLabel.text = CNLabeledValue.localizedStringForLabel(label)
                } else {
                    cell.titleLabel.text = ""
                }

                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("AllMails", forIndexPath: indexPath)
                cell.textLabel?.text = NSLocalizedString("allMessages", comment: "show all messages")
                return cell
            case 3 where (keyRecord?.hasKey) ?? false:
                let cell = tableView.dequeueReusableCellWithIdentifier("KeyCell", forIndexPath: indexPath)
                cell.textLabel?.text = NSLocalizedString("Details", comment: "Details")
                return cell
            case 3 where !((keyRecord?.hasKey) ?? false):
                let cell = tableView.dequeueReusableCellWithIdentifier("RecordCell", forIndexPath: indexPath) as! RecordCell
                if let r = otherRecords {
                    if let key = r[indexPath.row].key, let time = EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(key)?.discoveryTime {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.locale = NSLocale.currentLocale()
                        dateFormatter.dateStyle = .MediumStyle
                        cell.dateLabel.text = dateFormatter.stringFromDate(time)
                        cell.iconImage.image = IconsStyleKit.imageOfLetter
                    } else {
                        cell.dateLabel.text = ""
                        cell.iconImage.image = IconsStyleKit.imageOfPostcard
                    }
                    cell.label.text = r[indexPath.row].addresses.first?.mailAddress
                }
                return cell
            case 4 where !((keyRecord?.hasKey) ?? false):
                let cell = tableView.dequeueReusableCellWithIdentifier("KeyCell", forIndexPath: indexPath)
                cell.textLabel?.text = "abc"
                return cell
            case 4 where (keyRecord?.hasKey) ?? false:
                let cell = tableView.dequeueReusableCellWithIdentifier("RecordCell", forIndexPath: indexPath) as! RecordCell
                if let r = otherRecords {
                    if let key = r[indexPath.row].key, let time = EnzevalosEncryptionHandler.getEncryption(.PGP)?.getKey(key)?.discoveryTime {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.locale = NSLocale.currentLocale()
                        dateFormatter.dateStyle = .MediumStyle
                        cell.dateLabel.text = dateFormatter.stringFromDate(time)
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
        return tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath)
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var sections = 3
        if keyRecord?.ezContact.records.count > 1 {
            sections += 1
        }
        if let hasKey = keyRecord?.hasKey where hasKey {
            sections += 1
        }
        return sections
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let con = keyRecord {
            switch section {
            case 0:
                if !con.isVerified {
                    return 2
                }
            case 1:
                return con.ezContact.getMailAddresses().count
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

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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

    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Mit diesem Kontakt kommunizieren Sie zu 93% verschlüsselt und im Durchschnitt 2,3 x pro Woche." // Nur ein Test
        }
        return nil
    }
}

extension ContactViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }

    func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if indexPath.section == 1 {
            UIPasteboard.generalPasteboard().string = keyRecord!.ezContact.getMailAddresses()[indexPath.row].mailAddress
        }
    }
}

extension ContactViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .Push where (tableView.indexPathForSelectedRow?.section == 4 && ((keyRecord?.hasKey) ?? false) || tableView.indexPathForSelectedRow?.section == 3 && !((keyRecord?.hasKey) ?? false)) || tableView.indexPathForSelectedRow?.section == 0:
            return FlipTransition()
        default:
            return nil
        }
    }

    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

extension ContactViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
