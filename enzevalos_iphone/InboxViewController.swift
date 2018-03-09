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

class InboxViewController: UITableViewController, InboxCellDelegator {
    let dateFormatter = DateFormatter()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredRecords = [KeyRecord]()
    let folder = DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath)
    var loading = false {
        didSet {
            if loading {
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                activityIndicator.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
                activityIndicator.startAnimating()
                tableView.tableFooterView = activityIndicator
            } else {
                tableView.tableFooterView = nil
            }
        }
    }

    @IBOutlet weak var lastUpdateButton: UIBarButtonItem!
    var lastUpdateLabel = UILabel(frame: CGRect.zero)
    var lastUpdateText: String? {
        didSet {
            lastUpdateLabel.text = lastUpdateText
            lastUpdateLabel.sizeToFit()
        }
    }

    var lastUpdate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.barTintColor = ThemeManager.defaultColor

        tableView.sectionHeaderHeight = 1
        tableView.sectionFooterHeight = 0

        self.refreshControl?.addTarget(self, action: #selector(InboxViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")

        lastUpdateLabel.sizeToFit()
        lastUpdateLabel.backgroundColor = UIColor.clear
        lastUpdateLabel.textAlignment = .center
        lastUpdateLabel.font = UIFont.systemFont(ofSize: 13)
        lastUpdateLabel.textColor = UIColor.black
        lastUpdateButton.customView = lastUpdateLabel

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.scopeButtonTitles = [NSLocalizedString("Sender", comment: ""), NSLocalizedString("Subject", comment: ""), NSLocalizedString("Body", comment: ""), NSLocalizedString("All", comment: "")]
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        dateFormatter.locale = Locale.current
        dateFormatter.timeStyle = .medium

        tableView.register(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "inboxCell")

        AppDelegate.getAppDelegate().mailHandler.startIMAPIdleIfSupported(addNewMail: addNewMail)
        NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil, using: {
            [weak self] _ in
            self?.tableView.reloadData()
        })
    }

    func refresh(_ refreshControl: UIRefreshControl) {
        lastUpdateText = NSLocalizedString("Updating", comment: "Getting new data")
        let folder = DataHandler.handler.findFolder(with: UserManager.backendInboxFolderPath)
        AppDelegate.getAppDelegate().mailHandler.updateFolder(folder: folder, newMailCallback: addNewMail, completionCallback: getMailCompleted)

    }

    // TODO @Olli: Remove this function when MailHandler is cleaned up
    func addNewMail(mail: PersistentMail?) {
        //tableView.reloadData()
    }

    func getMailCompleted(_ error: Bool) {
        if let rc = self.refreshControl {
            if !error {
                lastUpdate = Date()
            }
            rc.endRefreshing()
            lastUpdateText = lastUpdate != nil ? "\(NSLocalizedString("LastUpdate", comment: "When the last update occured")): \(dateFormatter.string(from: lastUpdate!))" : NSLocalizedString("NeverUpdated", comment: "No internet connection since last launch")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()

        if lastUpdate == nil || Date().timeIntervalSince(lastUpdate!) > 30 {
            self.refreshControl?.beginRefreshingManually()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "inboxCell", for: indexPath) as! InboxTableViewCell

        cell.delegate = self
        if isFiltering {
            cell.enzContact = filteredRecords[indexPath.section]
        } else {
            cell.enzContact = folder.records[indexPath.section]
        }

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering {
            return filteredRecords.count
        }

        return folder.records.count
    }

    // set top and bottom seperator height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.01
        }
        return tableView.sectionHeaderHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func callSegueFromCell(_ mail: PersistentMail?) {
        if isFiltering, Logger.logging {
            let categoryIndex = searchController.searchBar.selectedScopeButtonIndex
            Logger.log(search: self.filteredRecords.count, category: categoryIndex, opened: "mail")
        }
        performSegue(withIdentifier: "readMailSegue", sender: mail)
    }

    func callSegueFromCell2(_ contact: KeyRecord?) {
        if isFiltering, Logger.logging {
            let categoryIndex = searchController.searchBar.selectedScopeButtonIndex
            Logger.log(search: self.filteredRecords.count, category: categoryIndex, opened: "mailList")
        }
        performSegue(withIdentifier: "mailListSegue", sender: contact)
    }

    func callSegueToContact(_ contact: KeyRecord?) {
        if isFiltering, Logger.logging {
            let categoryIndex = searchController.searchBar.selectedScopeButtonIndex
            Logger.log(search: self.filteredRecords.count, category: categoryIndex, opened: "contact")
        }
        performSegue(withIdentifier: "contactSegue", sender: contact)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "readMailSegue" {
            if let mail = sender as? PersistentMail {
                let DestinationViewController: ReadViewController = segue.destination as! ReadViewController
                DestinationViewController.mail = mail
            }
        } else if segue.identifier == "mailListSegue" {
            if let contact = sender as? KeyRecord {
                let DestinationViewController: ListViewController = segue.destination as! ListViewController
                DestinationViewController.contact = contact
            }
        } else if segue.identifier == "contactSegue" {
            if let contact = sender as? KeyRecord {
                let DestinationViewController: ContactViewController = segue.destination as! ContactViewController
                DestinationViewController.keyRecord = contact
            }
        } else if segue.identifier == "yourTraySegue" {
            if let DestinationNavigationController = segue.destination as? UINavigationController {
                if let DestinationViewController = DestinationNavigationController.topViewController as? ContactViewController {
                    DestinationViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
                    let records = folder.records.filter({
                        $0.addresses.contains(where: {
                            $0.mailAddress == UserManager.loadUserValue(.userAddr) as? String ?? ""
                        })
                    })
                    if let record = records.filter({ $0.isSecure }).first {
                        DestinationViewController.keyRecord = record
                    } else {
                        let keyID = UserManager.loadUserValue(Attribute.prefSecretKeyID) as! String
                        let addr = UserManager.loadUserValue(Attribute.userAddr) as! String
                        DestinationViewController.keyRecord = DataHandler.handler.getKeyRecord(addr: addr, keyID: keyID)
                    }
                }
            }
        }
    }

    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }

    /// Is true if the text is empty or nil
    var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }

    func filterContentForSearchText(_ searchText: String, scope: Int = 0) {
        var records = [KeyRecord]()
        if scope == 0 || scope == 3 {
            records += folder.records.filter({ ( record: KeyRecord) -> Bool in
                return record.name.lowercased().contains(searchText.lowercased())
            })
        }
        if scope == 1 || scope == 3 {
            records += folder.records.filter({ ( record: KeyRecord) -> Bool in
                let mails = record.inboxMails
                return mails.filter({ (mail: PersistentMail) -> Bool in
                    mail.subject?.lowercased().contains(searchText.lowercased()) ?? false
                }).count > 0
            })
        }
        if scope == 2 || scope == 3 {
            records += folder.records.filter({ ( record: KeyRecord) -> Bool in
                let mails = record.inboxMails
                return mails.filter({ (mail: PersistentMail) -> Bool in
                    if let decryptedBody = mail.decryptedBody {
                        return decryptedBody.lowercased().contains(searchText.lowercased())
                    } else if !mail.isEncrypted {
                        return mail.body?.lowercased().contains(searchText.lowercased()) ?? false
                    }
                    return false
                }).count > 0
            })
        }

        filteredRecords = records.unique.sorted()
        tableView.reloadData()
    }
}

extension InboxViewController: UISearchResultsUpdating {
    // https://www.raywenderlich.com/157864/uisearchcontroller-tutorial-getting-started

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!, scope: searchController.searchBar.selectedScopeButtonIndex)
    }
}

extension InboxViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: selectedScope)
    }
}

extension InboxViewController {
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height

        let reload_distance: CGFloat = 200
        if y > h + reload_distance && !loading {
            loading = true

            AppDelegate.getAppDelegate().mailHandler.loadMailsForInbox(newMailCallback: addNewMail, completionCallback: doneLoading)
        }
    }

    func doneLoading(_ error: Bool) {
        if error {
            // TODO: maybe we should do something about this? maybe not?
        }

        loading = false
    }
}

extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            if !uniqueValues.contains(item) {
                uniqueValues += [item]
            }
        }
        return uniqueValues
    }
}
