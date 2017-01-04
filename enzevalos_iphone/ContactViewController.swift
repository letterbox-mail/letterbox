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
    var contact: EnzevalosContact? = nil
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
//        headerCell.layoutMargins = UIEdgeInsetsZero
        
        setUI()
    }
    
    func setUI() {
        guard (contact != nil) else {
            return
        }
        if let con = contact {
            contactImage.image = con.contact.getImageOrDefault()
            contactImage.layer.cornerRadius = contactImage.frame.height / 2
            contactImage.clipsToBounds = true
            self.title = "\(con.contact.givenName) \(con.contact.familyName)"
            //self.title = CNContactFormatter.stringFromContact(con.contact, style: .FullName)
            
            if !con.isSecure {
                statusLabel.text = NSLocalizedString("noEncryption", comment: "Contact is not jet using encryption")
                actionButton.setTitle(NSLocalizedString("invite", comment: "Invide contact to use encryption"), forState: UIControlState.Normal)
            } else {
                statusLabel.text = NSLocalizedString("notVerified", comment: "Contact is not verified jet")
            }
            if con.isVerified {
                statusLabel.text = NSLocalizedString("Verified", comment: "Contact is verified")
            }
            
            prepareContactSheet()
        }
    }
    
    func prepareContactSheet() {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                ui = try AppDelegate.getAppDelegate().contactStore.unifiedContactWithIdentifier(contact!.contact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
            } catch {
                //contact doesn't exist or we don't have authorization
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
            vc = CNContactViewController(forNewContact: contact!.contact)
            vc!.contactStore = AppDelegate.getAppDelegate().contactStore // nötig?
            vc!.delegate = self
            addButton.addTarget(self, action: #selector(ContactViewController.showContact), forControlEvents: .TouchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
        }
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
            return eMailCell
        } else if indexPath.section == 2 {
            return newEMailCell
        }
        
        return allEMailsCell
    }
}
