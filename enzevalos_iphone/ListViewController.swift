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
    var contact: EnzevalosContact? {
        didSet {
            if let con = contact?.contact {
                self.title = con.givenName + " " + con.familyName
            }
        }
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = contact?.mails.count {
            return count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell") as! ListViewCell!
        
        if let mail = contact?.mails[indexPath.row] {
            cell.subjectLabel.text = mail.subject
            cell.bodyLabel.text = mail.body
            cell.dateLabel.text = mail.timeString
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("readMailSegue", sender: contact?.mails[indexPath.row])
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
