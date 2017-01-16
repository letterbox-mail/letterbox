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
    
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var contactStatus: UILabel!
    
    @IBOutlet weak var actionCell: UITableViewCell!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var headerCell: UITableViewCell!
    @IBOutlet weak var eMailCell: UITableViewCell!
    @IBOutlet weak var newEMailCell: UITableViewCell!
    @IBOutlet weak var allEMailsCell: UITableViewCell!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
//        headerCell.layoutMargins = UIEdgeInsetsZero
        print(contact?.cnContact?.getMailAddresses().count)
        
        setUI()
    }
    
    func setUI() {
        guard contact != nil else {
            return
        }
        if let con = contact {
            contactImage.image = con.getImageOrDefault()
            contactImage.layer.cornerRadius = contactImage.frame.height / 2
            contactImage.clipsToBounds = true
            self.title = con.name
            //self.title = CNContactFormatter.stringFromContact(con.contact, style: .FullName)
            
            if !con.isSecure {
                statusLabel.text = NSLocalizedString("noEncryption", comment: "Contact is not jet using encryption")
                actionButton.setTitle(NSLocalizedString("invite", comment: "Invide contact to use encryption"), forState: UIControlState.Normal)
            } else {
                statusLabel.text = NSLocalizedString("notVerified", comment: "Contact is not verified jet")
                actionButton.setTitle(NSLocalizedString("verifyNow", comment: "Verify now"), forState: UIControlState.Normal)
            }
            if con.isVerified {
                statusLabel.text = NSLocalizedString("Verified", comment: "Contact is verified")
            }
            
            prepareContactSheet()
            drawStatusCircle()
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
    
    func drawStatusCircle() {
        guard contact != nil else {
            return
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
        var bgColor: CGColor = UIColor.groupTableViewBackgroundColor().CGColor
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
        
        statusImage.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    func showContact() {
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
//        self.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
        prepareContactSheet()
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return headerCell
            } else if indexPath.row == 1 {
                return actionCell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCellWithIdentifier("mailCell") {
                cell.detailTextLabel?.text = "test"
                return cell
            } else {
                return eMailCell
            }
        } else if indexPath.section == 2 {
            return newEMailCell
        }
        
        return allEMailsCell
    }
}
