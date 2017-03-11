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
    var contact: KeyRecord? = nil
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
        if let con = contact {
            self.title = con.name
//            self.title = CNContactFormatter.stringFromContact(con.ezContact.cnContact, style: .FullName)

            prepareContactSheet()

            otherRecords = con.ezContact.records.filter({ $0 != contact }) // TODO: add unencrypted records to filter
        }
    }

    func prepareContactSheet() {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                uiContact = try AppDelegate.getAppDelegate().contactStore.unifiedContactWithIdentifier(contact!.cnContact!.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
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
            vc = CNContactViewController(forNewContact: contact!.cnContact)
            vc!.contactStore = AppDelegate.getAppDelegate().contactStore // nötig?
            vc!.delegate = self
            addButton.addTarget(self, action: #selector(ContactViewController.showContact), forControlEvents: .TouchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        }
    }

    func drawStatusCircle() -> UIImage? {
        guard contact != nil else {
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
        if contact!.isVerified {
            bgColor = Theme.Very_strong_security_indicator.encryptedVerifiedMessageColor.CGColor
        } else if !contact!.hasKey {
            bgColor = Theme.Very_strong_security_indicator.uncryptedMessageColor.CGColor
        }
        CGContextSetFillColorWithColor(context!, bgColor)
        CGContextFillRect(context!, CGRectMake(0, 0, myBounds.size.width, myBounds.size.height));

        let iconSize = CGFloat(50)
        let frame = CGRectMake(myBounds.size.width / 2 - iconSize / 2, myBounds.size.height / 2 - iconSize / 2, iconSize, iconSize)

        if contact!.hasKey {
            IconsStyleKit.drawLetter(frame: frame, fillBackground: true)
        } else if contact!.isVerified {
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
                controller!.toField = contact!.ezContact.getMailAddresses()[indexPath!.row].mailAddress
            }
        } else if segue.identifier == "mailList" {
            let DestinationViewController: ListViewController = segue.destinationViewController as! ListViewController
            DestinationViewController.contact = contact
        } else if segue.identifier == "otherRecord" {
            let DestinationViewController: ContactViewController = segue.destinationViewController as! ContactViewController
            let indexPath = tableView.indexPathForSelectedRow
            if let r = otherRecords {
                if let indexPath = indexPath where indexPath.section == 3 {
                    let destinationRecord = r[indexPath.row]
                    DestinationViewController.contact = destinationRecord
                } else {
                    DestinationViewController.contact = otherRecords!.first
                }
            }
        }
    }
}

extension ContactViewController: CNContactViewControllerDelegate {

}

extension ContactViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if contact != nil {
            switch indexPath.section {
            case 0:
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("ContactViewCell") as! ContactViewCell
                    cell.contactImage.image = contact!.cnContact!.getImageOrDefault()
                    cell.contactImage.layer.cornerRadius = cell.contactImage.frame.height / 2
                    cell.contactImage.clipsToBounds = true
                    cell.iconImage.image = drawStatusCircle()
                    if contact!.isVerified {
                        cell.contactStatus.text = NSLocalizedString("Verified", comment: "Contact is verified")
                    } else if contact!.hasKey {
                        cell.contactStatus.text = NSLocalizedString("notVerified", comment: "Contact is not verified jet")
                    } else if otherRecords?.filter({ $0.hasKey }).count > 0 {
                        cell.contactStatus.text = NSLocalizedString("otherEncryption", comment: "Contact is using encryption, this is the unsecure collection")
                    } else {
                        cell.contactStatus.text = NSLocalizedString("noEncryption", comment: "Contact is not jet using encryption")
                    }
                    return cell
                } else if indexPath.row == 1 {
                    let actionCell = tableView.dequeueReusableCellWithIdentifier("ActionCell", forIndexPath: indexPath) as! ActionCell
                    if contact!.hasKey {
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
                cell.detailLabel.text = contact!.cnContact?.getMailAddresses()[indexPath.item].mailAddress
                if let label = contact?.cnContact?.getMailAddresses()[indexPath.item].label.label {
                    cell.titleLabel.text = CNLabeledValue.localizedStringForLabel(label)
                } else {
                    cell.titleLabel.text = ""
                }

                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("AllMails", forIndexPath: indexPath)
                cell.textLabel?.text = NSLocalizedString("allMessages", comment: "show all messages")
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("RecordCell", forIndexPath: indexPath) as! RecordCell
                if let r = otherRecords {
                    cell.label.text = r[indexPath.row].addresses.first?.mailAddress
                    if r[indexPath.row].addresses.first?.label.label == "_$!<Work>!$_" {
                        cell.iconImage.image = LabelStyleKit.imageOfWork
                    } else if r[indexPath.row].addresses.first?.label.label == "_$!<Home>!$_" {
                        cell.iconImage.image = LabelStyleKit.imageOfHome
                    }
                    //                else if r[indexPath.row].addresses.first?.label.label?.containsString("other") {
                    //                    cell.iconImage.image = LabelStyleKit.imageOfOther
                    //                }
                }
                return cell
            default:
                break
            }
        }
        return tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath)
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if contact?.ezContact.records.count > 1 { // TODO: change later to only show this when there are more than 2 records
            return 4
        }
        return 3
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let con = contact {
            switch section {
            case 0:
                if !con.isVerified {
                    return 2
                }
            case 1:
                if let addresses = con.ezContact.addresses {
                    return addresses.count
                } else {
                    return 0
                }
            case 3:
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
        case 3:
            return NSLocalizedString("otherKeys", comment: "Other keys for this contact")
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
            UIPasteboard.generalPasteboard().string = contact!.ezContact.getMailAddresses()[indexPath.row].mailAddress
        }
    }
}

extension ContactViewController: UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .Pop:
            return nil // default
        case .Push:
            if tableView.indexPathForSelectedRow?.section == 3 || tableView.indexPathForSelectedRow?.section == 0 {
                return FlipTransition()
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

extension ContactViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
