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

    /*
    var contacts: [KeyRecord] = [] {
        didSet {
            self.contacts.sortInPlace({ $0 < $1 })
            if oldValue.count < contacts.count {
                self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            } else if oldValue.count > contacts.count {
                self.tableView.reloadData()
            } else {
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, contacts.count)), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }
 */

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


        //AppDelegate.getAppDelegate().mailHandler.delegate = self

        dateFormatter.locale = Locale.current
        dateFormatter.timeStyle = .medium

        tableView.register(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "inboxCell")

        AppDelegate.getAppDelegate().mailHandler.startIMAPIdleIfSupported(addNewMail: addNewMail)
    }

    func refresh(_ refreshControl: UIRefreshControl) {
        lastUpdateText = NSLocalizedString("Updating", comment: "Getting new data")
        AppDelegate.getAppDelegate().mailHandler.firstLookUp(newMailCallback: addNewMail, completionCallback: getMailCompleted)
      

    }
    
    func addNewMail() {
        tableView.reloadData()
    }

    func getMailCompleted(_ error: Bool) {
        if let rc = self.refreshControl {
            lastUpdate = Date()
            rc.endRefreshing()
            lastUpdateText = "\(NSLocalizedString("LastUpdate", comment: "When the last update occured")): \(dateFormatter.string(from: lastUpdate!))"
            // self.contacts.sortInPlace({ $0 < $1 })

            self.tableView.reloadData()
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
        cell.enzContact = DataHandler.handler.receiverRecords[indexPath.section]

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return DataHandler.handler.receiverRecords.count
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
        performSegue(withIdentifier: "readMailSegue", sender: mail)
    }

    //TODO: Whats that? What is the error?

    func callSegueFromCell2(_ contact: KeyRecord?) {
        performSegue(withIdentifier: "mailListSegue", sender: contact)
    }

    func callSegueToContact(_ contact: KeyRecord?) {
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
        }
    }
}
