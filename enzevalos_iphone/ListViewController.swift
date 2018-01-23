//
//  ListViewController.swift
//  enzevalos_iphone
//
//  Created by Joscha on 04.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit
import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}


class ListViewController: UITableViewController {
    let searchController = UISearchController(searchResultsController: nil)
    var filteredMails = [PersistentMail]()
    var contact: KeyRecord? {
        didSet {
            self.title = contact!.name
            if contact!.mails.count < 20 {
                loading = true
                AppDelegate.getAppDelegate().mailHandler.loadMailsForRecord(contact!, folderPath: UserManager.backendInboxFolderPath, newMailCallback: addNewMail, completionCallback: doneLoading)
            }
        }
    }
    var loading = false

    override func viewWillAppear(_ animated: Bool) {
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

        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: false)
    }

    func doneLoading(_ error: Bool) {
        if error {
            // TODO: maybe we should do something about this? maybe not?
        }

        loading = false
        tableView.reloadData()
    }

    func addNewMail(mail: PersistentMail?) {
        tableView.reloadData()
    }

    func filterContentForSearchText(_ searchText: String, scope: Int = 0) {
        filteredMails = contact!.mails.filter { mail in
            var returnValue = false
            switch scope {
            case 0:
                if let subject = mail.subject {
                    returnValue = subject.lowercased().contains(searchText.lowercased())
                }
            case 1:
                if !returnValue && mail.decryptedBody != nil {
                    returnValue = mail.decryptedBody!.lowercased().contains(searchText.lowercased())
                } else if !returnValue && mail.body != nil {
                    returnValue = mail.body!.lowercased().contains(searchText.lowercased())
                }
            case 2:
                if !returnValue && mail.cc?.count > 0 {
                    if let result = mail.cc?.contains(where: { cc -> Bool in
                        if let mail = cc as? MailAddress {
                            return mail.mailAddress.contains(searchText.lowercased())
                        }
                        return false
                    }) {
                        returnValue = result
                    }
                }
                if !returnValue && mail.getReceivers().count > 1 {
                    returnValue = mail.getReceivers().contains(where: { rec -> Bool in
                        return rec.mailAddress.contains(searchText.lowercased())
                    })
                }
            default:
                if let subject = mail.subject {
                    returnValue = subject.lowercased().contains(searchText.lowercased())
                }
                if !returnValue && mail.decryptedBody != nil {
                    returnValue = mail.decryptedBody!.lowercased().contains(searchText.lowercased())
                } else if !returnValue && mail.body != nil && !mail.isEncrypted {
                    returnValue = mail.body!.lowercased().contains(searchText.lowercased())
                }
                if !returnValue && mail.cc?.count > 0 {
                    if let res = mail.cc?.contains(where: { cc -> Bool in
                        if let mail = cc as? MailAddress {
                            return mail.mailAddress.contains(searchText.lowercased())
                        }
                        return false
                    }) {
                        returnValue = res
                    }
                }
                if !returnValue && mail.getReceivers().count > 1 {
                    returnValue = mail.getReceivers().contains(where: { rec -> Bool in
                        return rec.mailAddress.contains(searchText.lowercased())
                    })
                }
            }
            return returnValue
        }

        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMails.count
        }
        if let count = contact?.mails.count {
            return loading ? count + 1 : count
        } else {
            return loading ? 1 : 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mail: PersistentMail?

        if searchController.isActive && searchController.searchBar.text != "" {
            mail = filteredMails[indexPath.row]
        } else if indexPath.row >= contact?.mails.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell")
            return cell!
        } else {
            mail = contact?.mails[indexPath.row]
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell") as! ListViewCell!

        if mail != nil && !mail!.isRead {
            cell?.subjectLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        } else {
            cell?.subjectLabel.font = UIFont.systemFont(ofSize: 17.0)
        }
        cell?.subjectLabel.text = mail?.getSubjectWithFlagsString()
        cell?.bodyLabel.text = mail?.shortBodyString
        cell?.dateLabel.text = mail?.timeString

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mail: PersistentMail?

        if searchController.isActive && searchController.searchBar.text != "" {
            mail = filteredMails[indexPath.row]
            if Logger.logging {
                Logger.queue.async(flags: .barrier) {
                    Logger.log(search: self.filteredMails.count, category: self.searchController.searchBar.selectedScopeButtonIndex, opened: "searchedInMailList", keyRecordMailList: self.contact?.addresses)
                }
            }
        } else if indexPath.row >= contact?.mails.count {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        } else {
            mail = contact?.mails[indexPath.row]
        }
        performSegue(withIdentifier: "readMailSegue", sender: mail)
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
            AppDelegate.getAppDelegate().mailHandler.loadMailsForRecord(contact!, folderPath: UserManager.backendInboxFolderPath, newMailCallback: addNewMail, completionCallback: doneLoading)
            tableView.reloadData()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "readMailSegue" {
            if let mail = sender as? PersistentMail {
                let DestinationViewController: ReadViewController = segue.destination as! ReadViewController
                DestinationViewController.mail = mail
            }
        }
    }
}

extension ListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let _ = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: searchBar.selectedScopeButtonIndex)
    }
}

extension ListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: selectedScope)
    }
}
