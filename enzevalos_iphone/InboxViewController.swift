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

class InboxViewController : UITableViewController, InboxCellDelegator {
    var contacts: [EnzevalosContact] = [] {
        didSet {
            self.contacts.sortInPlace()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                print("Refreshed TableView")
            })
        }
    }
    let mailHandler = MailHandler()
    
    func addNewMail(mail: Mail) {
        var isAdded = false
        for contact in contacts {
            for address in contact.contact.emailAddresses {
                if address.value as? String == mail.sender?.mailbox {
                    // Kontakt existiert bereits
                    if !contact.mails.contains(mail) {
                        contact.mails.append(mail)
                    }
                    isAdded = true
                }
            }
        }
        // TODO: Check if contact exists in address book
        
        if !isAdded {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionHeaderHeight = 1
        tableView.sectionFooterHeight = 0
        
        self.refreshControl?.addTarget(self, action: #selector(InboxViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
//        random mail generation
//        contacts = generateMail()
        self.mailHandler.delegate = self
        self.mailHandler.recieve()
        
        
        tableView.registerNib(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "inboxCell")
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        print("refresh")
        self.mailHandler.recieve()
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
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
