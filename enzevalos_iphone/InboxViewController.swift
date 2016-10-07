//
//  InboxViewController.swift
//  readView
//
//  Created by Joscha on 26.08.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import UIKit
import Foundation
import Contacts

class InboxViewController : UITableViewController, InboxCellDelegator, MailHandlerDelegator {
    var contacts: [EnzevalosContact] = [] {
        didSet {
            self.contacts.sortInPlace()
            if oldValue.count < contacts.count {
                self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            } else if oldValue.count > contacts.count {
                self.tableView.reloadData()
            } else {
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, contacts.count)), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }

let mailHandler = MailHandler()
    
    @IBOutlet weak var lastUpdateButton: UIBarButtonItem!
    var lastUpdateLabel = UILabel(frame: CGRectZero)
    var lastUpdateText: String? {
        didSet {
            lastUpdateLabel.text = lastUpdateText
            lastUpdateLabel.sizeToFit()
        }
    }
    
    var lastUpdate: NSDate?

    func addNewMail(mail: Mail) {
        for contact in contacts {
            for address in contact.contact.emailAddresses {
                if address.value as? String == mail.sender?.mailbox {
                    // Kontakt existiert bereits
                    if !contact.mails.contains(mail) {
                        contact.mails.append(mail)
                    }
                    return
                }
            }
        }
        // TODO: Check if contact exists in address book
        
        // Neuer Kontakt muss angelegt werden
        let con = CNMutableContact()
        let name = mail.sender?.displayName
        if let n = name {
            let nameArray = n.characters.split(" ").map(String.init)
            if let n = nameArray.first {
                con.givenName = n
            }
            if let fam = nameArray.last {
                con.familyName = fam
            } else {
                con.givenName = "NO"
                con.familyName = "NAME"
            }
        }
        con.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: mail.sender!.mailbox)]
        contacts.append(EnzevalosContact(contact: con, mails: [mail]))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionHeaderHeight = 1
        tableView.sectionFooterHeight = 0
        
        self.refreshControl?.addTarget(self, action: #selector(InboxViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        
        lastUpdateLabel.sizeToFit()
        lastUpdateLabel.backgroundColor = UIColor.clearColor()
        lastUpdateLabel.textAlignment = .Center
        lastUpdateLabel.font = UIFont.systemFontOfSize(13)
        lastUpdateLabel.textColor = UIColor.blackColor()
        lastUpdateButton.customView = lastUpdateLabel
        
//        random mail generation
//        contacts = generateMail()
        
        self.mailHandler.delegate = self
        
        tableView.registerNib(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "inboxCell")
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        lastUpdateText = "Updating..."
        self.mailHandler.recieve()
    }
    
    func getMailCompleted() {
        if let rc = self.refreshControl {
            lastUpdate = NSDate()
            rc.endRefreshing()
            lastUpdateText = "Just refreshed"
            self.contacts.sortInPlace()
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
        if lastUpdate == nil || NSDate().timeIntervalSinceDate(lastUpdate!) > 30 {
            self.refreshControl?.beginRefreshingManually()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("inboxCell", forIndexPath: indexPath) as! InboxTableViewCell
        
        cell.delegate = self
        cell.enzContact = contacts[indexPath.section]

        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return contacts.count
    }
    
    // set top and bottom seperator height
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.01
        }
        return tableView.sectionHeaderHeight
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func callSegueFromCell(mail: Mail?) {
        performSegueWithIdentifier("readMailSegue", sender: mail)
    }
    
    func callSegueFromCell(contact: EnzevalosContact?) {
        performSegueWithIdentifier("mailListSegue", sender: contact)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "readMailSegue" {
            if let mail = sender as? Mail {
                let DestinationViewController: ReadViewController = segue.destinationViewController as! ReadViewController
                DestinationViewController.mail = mail
            }
        } else if segue.identifier == "mailListSegue" {
            if let contact = sender as? EnzevalosContact {
                let DestinationViewController: ListViewController = segue.destinationViewController as! ListViewController
                DestinationViewController.contact = contact
            }
        }
    }
}
