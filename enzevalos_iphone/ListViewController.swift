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
            if contact!.mails.count < 20 {
                loading = true
                AppDelegate.getAppDelegate().mailHandler.loadMoreMails(contact!, newMailCallback: addNewMail, completionCallback: doneLoading)
            }
        }
    }
    var loading = false

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

    func doneLoading(error: Bool) {
        if error {
            // TODO: maybe we should do something about this? maybe not?
        }

        loading = false
        tableView.reloadData()
    }

    func addNewMail() {
        tableView.reloadData()
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
                if !returnValue && mail.decryptedBody != nil {
                    returnValue = mail.decryptedBody!.lowercaseString.containsString(searchText.lowercaseString)
                } else if !returnValue && mail.body != nil {
                    returnValue = mail.body!.lowercaseString.containsString(searchText.lowercaseString)
                }
            case 2:
                if !returnValue && mail.cc?.count > 0 {
                    if let result = mail.cc?.contains({ cc -> Bool in
                        if let mail = cc as? MailAddress {
                            return mail.mailAddress.containsString(searchText.lowercaseString)
                        }
                        return false
                    }) {
                        returnValue = result
                    }
                }
                if !returnValue && mail.getReceivers().count > 1 {
                    returnValue = mail.getReceivers().contains({ rec -> Bool in
                        return rec.mailAddress.containsString(searchText.lowercaseString)
                    })
                }
            default:
                if let subject = mail.subject {
                    returnValue = subject.lowercaseString.containsString(searchText.lowercaseString)
                }
                if !returnValue && mail.decryptedBody != nil {
                    returnValue = mail.decryptedBody!.lowercaseString.containsString(searchText.lowercaseString)
                } else if !returnValue && mail.body != nil {
                    returnValue = mail.body!.lowercaseString.containsString(searchText.lowercaseString)
                }
                if !returnValue && mail.cc?.count > 0 {
                    if let res = mail.cc?.contains({ cc -> Bool in
                        if let mail = cc as? MailAddress {
                            return mail.mailAddress.containsString(searchText.lowercaseString)
                        }
                        return false
                    }) {
                        returnValue = res
                    }
                }
                if !returnValue && mail.getReceivers().count > 1 {
                    returnValue = mail.getReceivers().contains({ rec -> Bool in
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
            return loading ? count + 1: count
        } else {
            return loading ? 1 : 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let mail: Mail?

        if searchController.active && searchController.searchBar.text != "" {
            mail = filteredMails[indexPath.row]
        } else if indexPath.row >= contact?.mails.count {
            let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell")
            return cell!
        } else {
            mail = contact?.mails[indexPath.row]
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell") as! ListViewCell!

        if mail != nil && !mail!.isRead {
            cell.subjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
        } else {
            cell.subjectLabel.font = UIFont.systemFontOfSize(17.0)
        }
        cell.subjectLabel.text = mail?.getSubjectWithFlagsString()
        cell.bodyLabel.text = mail?.shortBodyString
        cell.dateLabel.text = mail?.timeString

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let mail: Mail?

        if searchController.active && searchController.searchBar.text != "" {
            mail = filteredMails[indexPath.row]
        } else if indexPath.row >= contact?.mails.count {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        } else {
            mail = contact?.mails[indexPath.row]
        }
        performSegueWithIdentifier("readMailSegue", sender: mail)
    }

    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height

        let reload_distance: CGFloat = 50
        if y > h + reload_distance && !loading {
            print("loading new mail because we scrolled to the bottom")
            loading = true
            AppDelegate.getAppDelegate().mailHandler.loadMoreMails(contact!, newMailCallback: addNewMail, completionCallback: doneLoading)
            tableView.reloadData()
        }
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
        let _ = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: searchBar.selectedScopeButtonIndex)
    }
}

extension ListViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: selectedScope)
    }
}
