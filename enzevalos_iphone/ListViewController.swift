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
    let searchController = UISearchController(searchResultsController: nil)
    var filteredMails = [Mail]()
    var contact: KeyRecord? {
        didSet {
            self.title = contact!.name
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.scopeButtonTitles = [NSLocalizedString("Subject", comment: ""), NSLocalizedString("Body", comment: ""), NSLocalizedString("CC", comment: ""), NSLocalizedString("All", comment: "")]
        searchController.searchBar.delegate = self
        
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
    }
    
    func filterContentForSearchText(searchText: String, scope: Int = 0) {
        filteredMails = contact!.mails.filter { mail in
            var returnValue = false
            switch scope {
            case 0:
                if let subject = mail.subject {
                    returnValue = subject.lowercaseString.containsString(searchText.lowercaseString)
                }
            case 1:
                if !returnValue && mail.decryptedMessage != nil {
                    returnValue = mail.decryptedMessage!.lowercaseString.containsString(searchText.lowercaseString)
                } else if !returnValue && mail.body != nil {
                    returnValue = mail.body!.lowercaseString.containsString(searchText.lowercaseString)
                }
            case 2:
                if !returnValue && mail.cc?.count > 0 {
                    if let result = mail.cc?.contains({cc -> Bool in
                        if let mail = cc as? MailAddress {
                            return mail.mailAddress.containsString(searchText.lowercaseString)
                        }
                        return false
                    }) {
                        returnValue = result
                    }
                }
                if !returnValue && mail.getReceivers().count > 1 {
                    returnValue = mail.getReceivers().contains({rec -> Bool in
                        return rec.mailAddress.containsString(searchText.lowercaseString)
                    })
                }
            default:
                if let subject = mail.subject {
                    returnValue = subject.lowercaseString.containsString(searchText.lowercaseString)
                }
                if !returnValue && mail.decryptedMessage != nil {
                    returnValue = mail.decryptedMessage!.lowercaseString.containsString(searchText.lowercaseString)
                } else if !returnValue && mail.body != nil {
                    returnValue = mail.body!.lowercaseString.containsString(searchText.lowercaseString)
                }
                if !returnValue && mail.cc?.count > 0 {
                    if let res = mail.cc?.contains({cc -> Bool in
                        if let mail = cc as? MailAddress {
                            return mail.mailAddress.containsString(searchText.lowercaseString)
                        }
                        return false
                    }) {
                        returnValue = res
                    }
                }
                if !returnValue && mail.getReceivers().count > 1 {
                    returnValue = mail.getReceivers().contains({rec -> Bool in
                        return rec.mailAddress.containsString(searchText.lowercaseString)
                    })
                }
            }
            return returnValue
        }
        
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredMails.count
        }
        if let count = contact?.mails.count {
            return count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell") as! ListViewCell!
        let mail: Mail?
        
        if searchController.active && searchController.searchBar.text != "" {
            mail = filteredMails[indexPath.row]
        } else {
            mail = contact?.mails[indexPath.row]
        }
        
        if mail != nil && !mail!.isRead {
            cell.subjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
        } else {
            cell.subjectLabel.font = UIFont.systemFontOfSize(17.0)
        }
        cell.subjectLabel.text = mail?.getSubjectWithFlagsString()
        cell.bodyLabel.text = mail?.body
        cell.dateLabel.text = mail?.timeString
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let mail: Mail?
        
        if searchController.active && searchController.searchBar.text != "" {
            mail = filteredMails[indexPath.row]
        } else {
            mail = contact?.mails[indexPath.row]
        }
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

extension ListViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: searchBar.selectedScopeButtonIndex)
    }
}

extension ListViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: selectedScope)
    }
}
