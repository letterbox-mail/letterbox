//
//  ListViewController.swift
//  enzevalos_iphone
//
//  Created by Joscha on 04.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit
import Foundation

class ListViewController: UITableViewController {
    var contact: KeyRecord? {
        didSet {
                self.title = contact!.name
        }
    }

    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = contact?.getFromMails().count {
            return count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell") as! ListViewCell!
        
        if let mail = contact?.getFromMails()[indexPath.row] {
            if mail.isUnread() {
                cell.subjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
            } else {
                cell.subjectLabel.font = UIFont.systemFontOfSize(17.0)
            }
            cell.subjectLabel.text = mail.getSubjectWithFlagsString()
            cell.bodyLabel.text = mail.body
            cell.dateLabel.text = mail.timeString
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("readMailSegue", sender: contact?.getFromMails()[indexPath.row])
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
