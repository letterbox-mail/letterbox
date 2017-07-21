//
//  FolderViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 21.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class FolderViewController: UITableViewController {
    
    var folders: [Folder] = []
    
    var isFirstFolderViewController = true
    var presentedFolder: Folder? = nil
    
    override func viewDidLoad() {
        self.refreshControl?.addTarget(self, action: #selector(FolderViewController.refresh), for: UIControlEvents.valueChanged)
        
        if isFirstFolderViewController {
            DataHandler.handler.callForFolders()
            navigationItem.title = NSLocalizedString("Folders", comment: "")
            folders = DataHandler.handler.allFolders
        }
        else {
            navigationItem.setLeftBarButton(navigationItem.backBarButtonItem, animated: false)
        }
        if let thisFolder = presentedFolder {
            navigationItem.title = thisFolder.name
            refreshControl?.beginRefreshing()
            AppDelegate.getAppDelegate().mailHandler.firstLookUp(thisFolder.path, newMailCallback: newMails, completionCallback: endRefreshing)
            if let set = thisFolder.subfolder, let subFolders = set.allObjects as? [Folder] {
                folders = subFolders
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        var count = 0
        
        if isFirstFolderViewController {
            count += 1
        }
        if folders.count > 0 {
            count += 1
        }
        if let thisFolder = presentedFolder {
            if getMails().count > 0 {
                count += 1
            }
        }
        
        return count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionType(IndexPath.init(row: 0, section: section)) == .inbox {
           return 1
        }
        if sectionType(IndexPath.init(row: 0, section: section)) == .folders {
            return folders.count
        }
        return getMails().count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sectionType(indexPath) == .mails {
            return 71
        }
        return 44
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell") as! FolderCell
        if sectionType(indexPath) == .inbox {
            cell.folderName.text = "Inbox"
            cell.folderImage.image = #imageLiteral(resourceName: "Inbox")
        }
        else if sectionType(indexPath) == .mails {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "folderListCell") as? FolderListCell{
                let mail = getMails()[indexPath.row]
                
                cell.body.text = mail.body
                if let contact = mail.from.contact {
                    cell.from.text = contact.name
                }
                else {
                    cell.from.text = mail.from.mailAddress
                }
                cell.from.font = UIFont.boldSystemFont(ofSize: cell.from.font.pointSize)
                cell.subject.text = mail.subject
                cell.date.text = mail.timeString
                
                if mail.isSecure {
                    cell.secureImageView.image = IconsStyleKit.imageOfLetter
                }
                else {
                    cell.secureImageView.image = IconsStyleKit.imageOfPostcard
                }
                if !mail.isRead {
                    cell.markImageView.image = "🔵".image()
                    cell.body.font = UIFont.boldSystemFont(ofSize: cell.body.font.pointSize)
                    cell.subject.font = UIFont.boldSystemFont(ofSize: cell.subject.font.pointSize)
                }
                if mail.isAnwered {
                    cell.replyImageView.image = "↩️".image()
                }
                
                if let markImageView = cell.markImageView {
                    if markImageView.image == nil {
                        cell.stackView.removeArrangedSubview(cell.markImageView)
                    }
                    else {
                        cell.stackView.addArrangedSubview(cell.markImageView)
                    }
                }
                
                
                if let replyImageView = cell.replyImageView {
                    if replyImageView.image == nil {
                        cell.stackView.removeArrangedSubview(cell.replyImageView)
                    }
                    else {
                        cell.stackView.addArrangedSubview(cell.replyImageView)
                    }
                }
                
                return cell
            }
        }
        else if indexPath.row < folders.count {
            cell.folderName.text = folders[indexPath.row].name
            cell.folderImage.image = getImage(for: folders[indexPath.row].name)
        }
            
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sectionType(indexPath) == .inbox {
            performSegue(withIdentifier: "showInboxSegue", sender: nil)
        }
        else if sectionType(indexPath) == .mails {
            performSegue(withIdentifier: "readFolderMailSegue", sender: getMails()[indexPath.row])
        }
        else {
            if true {
                let vc = storyboard?.instantiateViewController(withIdentifier: "folderViewController") as! FolderViewController
                vc.folders = []
                vc.isFirstFolderViewController = false
                vc.presentedFolder = folders[indexPath.row]
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                performSegue(withIdentifier: "showFolderListSegue", sender: folders[indexPath.row])
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "readFolderMailSegue" {
            let destinationVC = segue.destination as! ReadViewController
            if let mail = sender as? PersistentMail {
                destinationVC.mail = mail
            }
        } else if segue.identifier == "showFolderListSegue" {
            let destinationVC = segue.destination as! FolderListViewController
            if let folder = sender as? Folder {
                destinationVC.folder = folder
            }
        }
    }
    
    func refresh() {
        if let thisFolder = presentedFolder {
            refreshControl?.beginRefreshing()
            AppDelegate.getAppDelegate().mailHandler.olderMailsFolder(thisFolder.path, newMailCallback: newMails, completionCallback: endRefreshing(_:))
        }
        else {
            DataHandler.handler.callForFolders()
            endRefreshing(false)
        }
    }
    func endRefreshing(_ error: Bool) {
        if let thisFolder = presentedFolder {
            if let set = thisFolder.subfolder, let subFolders = set.allObjects as? [Folder] {
                folders = subFolders
            }
        }
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
    func newMails() {
        print("newMails")
    }
    
    func getImage(for name: String) -> UIImage {
        if false /*folders*/ {
            return #imageLiteral(resourceName: "Inbox")
        }
        return #imageLiteral(resourceName: "Inbox")
    }
    func getMails() -> [PersistentMail] {
        if let folder = self.presentedFolder {
            return folder.mailsOfFolder.sorted()
        }
        return []
    }
    func sectionType(_ indexPath: IndexPath) -> FolderViewSectionType {
        if indexPath.section >= 2
            || indexPath.section == 1 && (!isFirstFolderViewController || folders.count <= 0)
            || indexPath.section == 0 && !isFirstFolderViewController && folders.count <= 0 {
            
            return FolderViewSectionType.mails
        } else if indexPath.section == 1 && isFirstFolderViewController
            || indexPath.section == 0 && !isFirstFolderViewController {
            
            return FolderViewSectionType.folders
        }
        return FolderViewSectionType.inbox
    }
}

enum FolderViewSectionType: Int {
    case inbox = 0, folders, mails
}
