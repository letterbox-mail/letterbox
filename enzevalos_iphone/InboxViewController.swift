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
    var contacts: [EnzevalosContact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionHeaderHeight = 1
        tableView.sectionFooterHeight = 0
        
        contacts = generateMail()
        contacts.sortInPlace()
        
        tableView.registerNib(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "inboxCell")
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "readMailSegue" {
            if let mail = sender as? Mail {
                let DestinationViewController: ReadViewController = segue.destinationViewController as! ReadViewController
                DestinationViewController.mail = mail
            }
        }
    }    
}