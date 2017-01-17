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

class ContactViewController: UITableViewController, CNContactViewControllerDelegate {
    var contact: KeyRecord? = nil
    private var ui: CNContact? = nil
    private var vc: CNContactViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
        
//        headerCell.layoutMargins = UIEdgeInsetsZero
        if let con = contact {
            self.title = con.name
//            self.title = CNContactFormatter.stringFromContact(con.ezContact.cnContact, style: .FullName)
            
            prepareContactSheet()
        }
    }
    
    func prepareContactSheet() {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                ui = try AppDelegate.getAppDelegate().contactStore.unifiedContactWithIdentifier(contact!.cnContact!.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            } catch {
                //contact doesn't exist or we don't have authorization
                //TODO: handle missing authorization
            }
        }
        if let conUI = ui {
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
        
        //
        // Clip context to a circle
        //
        let path = CGPathCreateWithEllipseInRect(myBounds, nil);
        CGContextAddPath(context!, path);
        CGContextClip(context!);
        
        
        //
        // Fill background of context
        //
        var bgColor: CGColor = ThemeManager.defaultColor.CGColor
        if contact!.isVerified {
            bgColor = Theme.Very_strong_security_indicator.encryptedVerifiedMessageColor.CGColor
        } else if !contact!.isSecure {
            bgColor = Theme.Very_strong_security_indicator.uncryptedMessageColor.CGColor
        }
        CGContextSetFillColorWithColor(context!, bgColor)
        CGContextFillRect(context!, CGRectMake(0, 0, myBounds.size.width, myBounds.size.height));
        
        let iconSize = CGFloat(50)
        let frame = CGRectMake(myBounds.size.width/2 - iconSize/2, myBounds.size.height/2 - iconSize/2, iconSize, iconSize)

        if contact!.isSecure {
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let con = contact {
                if !con.isVerified {
                    return 2
                }
            }
        } else if section == 1 {
            if let con = contact {
                if let addresses = con.ezContact.addresses {
                    return addresses.count
                } else {
                    return 0
                }
            }
        }
        
        return 1
    }

    override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if indexPath.section == 1 {
            UIPasteboard.generalPasteboard().string = contact!.ezContact.getMailAddresses()[indexPath.row].mailAddress
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("ContactViewCell") as! ContactViewCell
                cell.contactImage.image = contact!.cnContact!.getImageOrDefault()
                cell.contactImage.layer.cornerRadius = cell.contactImage.frame.height / 2
                cell.contactImage.clipsToBounds = true
                cell.iconImage.image = drawStatusCircle()
                if contact!.isVerified {
                    cell.contactStatus.text = NSLocalizedString("Verified", comment: "Contact is verified")
                } else if contact!.isSecure {
                    cell.contactStatus.text = NSLocalizedString("notVerified", comment: "Contact is not verified jet")
                } else {
                    cell.contactStatus.text = NSLocalizedString("noEncryption", comment: "Contact is not jet using encryption")
                }
                return cell
            } else if indexPath.row == 1 {
                let actionCell = tableView.dequeueReusableCellWithIdentifier("ActionCell", forIndexPath: indexPath) as! ActionCell
                if contact!.isSecure {
                    actionCell.Button.setTitle(NSLocalizedString("verifyNow", comment: "Verify now"), forState: .Normal)
                } else {
                    actionCell.Button.setTitle(NSLocalizedString("invite", comment: "Invide contact to use encryption"), forState: .Normal)
                }
                return actionCell
            }
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("MailCell") as! MailCell
            cell.detailLabel.text = contact!.cnContact?.getMailAddresses()[indexPath.item].mailAddress
            if let label = contact?.cnContact?.getMailAddresses()[indexPath.item].label.label {
                cell.titleLabel.text = CNLabeledValue.localizedStringForLabel(label)
            } else {
                cell.titleLabel.text = ""
            }
            
            return cell
            
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCellWithIdentifier("allMails", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("allMessages", comment: "show all messages")
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "newMail"{
            let navigationController = segue.destinationViewController as? UINavigationController
            let controller = navigationController?.topViewController as? SendViewController
            let indexPath = tableView.indexPathForSelectedRow
            if controller != nil {
                // TODO: add address to SendView
//                controller?.toText.delegate?.tokenField!((controller?.toText)!, didEnterText: (contact?.ezContact.getMailAddresses()[(indexPath?.row)!].mailAddress)!)
            }
        } else if segue.identifier == "mailList" {
            let DestinationViewController: ListViewController = segue.destinationViewController as! ListViewController
            DestinationViewController.contact = contact
        }
    }
}
