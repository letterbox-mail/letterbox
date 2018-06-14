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

    @IBOutlet weak var lastUpdateButton: UIBarButtonItem!
    var lastUpdateLabel = UILabel(frame: CGRect.zero)
    var lastUpdateText: String? {
        didSet {
            lastUpdateLabel.text = lastUpdateText
            lastUpdateLabel.sizeToFit()
        }
    }
    
    var lastUpdate: Date? = Date()
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        self.refreshControl?.addTarget(self, action: #selector(FolderViewController.refresh), for: UIControlEvents.valueChanged)
        self.refreshControl?.attributedTitle = NSAttributedString(string: NSLocalizedString("PullToRefresh", comment: "Pull to refresh"))
        lastUpdateText = NSLocalizedString("Updating", comment: "Getting new data")

        if isFirstFolderViewController {
            folders = DataHandler.handler.allRootFolders.sorted().filter { $0.path != UserManager.backendInboxFolderPath }
            DataHandler.handler.callForFolders(done: endRefreshing)
            navigationItem.title = NSLocalizedString("Folders", comment: "")
        } else {
            navigationItem.setLeftBarButton(navigationItem.backBarButtonItem, animated: false)
        }
        if let thisFolder = presentedFolder {
            navigationItem.title = UserManager.convertToFrontendFolderPath(from: thisFolder.name)
            refreshControl?.beginRefreshing()
            AppDelegate.getAppDelegate().mailHandler.updateFolder(folder: thisFolder, completionCallback: endRefreshing)
            folders = thisFolder.subfolders.sorted()
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil, using: {
            [weak self] _ in
            self?.lastUpdate = Date()
            self?.tableView.reloadData()
        })
        
        dateFormatter.locale = Locale.current
        dateFormatter.timeStyle = .medium
        
        lastUpdateLabel.sizeToFit()
        lastUpdateLabel.backgroundColor = UIColor.clear
        lastUpdateLabel.textAlignment = .center
        lastUpdateLabel.font = UIFont.systemFont(ofSize: 13)
        lastUpdateLabel.textColor = UIColor.black
        lastUpdateButton.customView = lastUpdateLabel
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
        if presentedFolder != nil {
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
        } else if sectionType(indexPath) == .mails {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "folderListCell") as? FolderListCell {
                let mail = getMails()[indexPath.row]

                cell.body.text = mail.body
                if let contact = mail.from.contact {
                    cell.from.text = contact.name
                } else {
                    cell.from.text = mail.from.mailAddress
                }
                cell.from.font = UIFont.boldSystemFont(ofSize: cell.from.font.pointSize)
                cell.subject.text = mail.subject
                cell.date.text = mail.timeString

                if mail.isSecure {
                    cell.secureImageView.image = IconsStyleKit.imageOfLetter
                } else if mail.trouble {
                    cell.secureImageView.image = IconsStyleKit.imageOfLetterCorrupted
                } else {
                    cell.secureImageView.image = IconsStyleKit.imageOfPostcard
                }
                if !mail.isRead {
                    cell.markImageView.image = "🔵".image()
                    cell.body.font = UIFont.boldSystemFont(ofSize: cell.body.font.pointSize)
                    cell.subject.font = UIFont.boldSystemFont(ofSize: cell.subject.font.pointSize)
                } else {
                    cell.markImageView.image = nil
                    cell.body.font = UIFont.systemFont(ofSize: cell.body.font.pointSize)
                    cell.subject.font = UIFont.systemFont(ofSize: cell.subject.font.pointSize)
                }
                if mail.isAnwered {
                    cell.replyImageView.image = "↩️".image()
                } else {
                    cell.replyImageView.image = nil
                }

                if let markImageView = cell.markImageView {
                    if markImageView.image == nil {
                        cell.stackView.removeArrangedSubview(cell.markImageView)
                    } else {
                        cell.stackView.addArrangedSubview(cell.markImageView)
                    }
                }


                if let replyImageView = cell.replyImageView {
                    if replyImageView.image == nil {
                        cell.stackView.removeArrangedSubview(cell.replyImageView)
                    } else {
                        cell.stackView.addArrangedSubview(cell.replyImageView)
                    }
                }

                return cell
            }
        } else if indexPath.row < folders.count {
            cell.folderName.text = folders[indexPath.row].frontendName
            cell.folderImage.image = getImage(for: UserManager.convertToFrontendFolderPath(from: folders[indexPath.row].path, with: folders[indexPath.row].delimiter))
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sectionType(indexPath) == .inbox {
            performSegue(withIdentifier: "showInboxSegue", sender: nil)
        } else if sectionType(indexPath) == .mails {
            performSegue(withIdentifier: "readFolderMailSegue", sender: getMails()[indexPath.row])
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "folderViewController") as! FolderViewController
            vc.folders = []
            vc.isFirstFolderViewController = false
            vc.presentedFolder = folders[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "readFolderMailSegue" {
            if let destinationVC = segue.destination as? ReadViewController, let mail = sender as? PersistentMail {
                destinationVC.mail = mail
            }
        }
    }

    @objc func refresh() {
        lastUpdateText = NSLocalizedString("Updating", comment: "Getting new data")
        if let thisFolder = presentedFolder {
            refreshControl?.beginRefreshing()
            AppDelegate.getAppDelegate().mailHandler.updateFolder(folder: thisFolder, completionCallback: endRefreshing(_:))
        } else {
            DataHandler.handler.callForFolders(done: endRefreshing)
        }
    }
    func endRefreshing(_ error: Error?) {
        if let thisFolder = presentedFolder {
            folders = thisFolder.subfolders.sorted()
            presentedFolder = thisFolder
        }
        if isFirstFolderViewController {
            folders = DataHandler.handler.allRootFolders.sorted().filter { $0.path != UserManager.backendInboxFolderPath }
        }
        tableView.reloadData()
        refreshControl?.endRefreshing()
        lastUpdateText = lastUpdate != nil ? "\(NSLocalizedString("LastUpdate", comment: "When the last update occured")): \(dateFormatter.string(from: lastUpdate!))" : NSLocalizedString("NeverUpdated", comment: "No internet connection since last launch")
    }
   
    func getImage(for path: String) -> UIImage {
        if path == UserManager.frontendInboxFolderPath {
            return #imageLiteral(resourceName: "Inbox")
        }
        /* TODO: Add more in here*/
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

//inspired by https://stackoverflow.com/questions/38809425/convert-apple-emoji-string-to-uiimage
extension String {
    func image() -> UIImage {
        let size = CGSize(width: 30, height: 35)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        UIColor.white.set()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
