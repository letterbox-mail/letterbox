//
//  FolderViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 21.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class FolderViewController: UITableViewController {
    
    static var foldersStatic: [String] = ["Inbox", "Drafts", "Send", "Trash"]
    
    var folders: [String] = ["Inbox", "Drafts", "Send", "Trash"]//[]
    
    var isFirstFolderViewController = true
    //var presentedFolder:  = nil
    
    override func viewDidLoad() {
        self.refreshControl?.addTarget(self, action: #selector(FolderViewController.refresh), for: UIControlEvents.valueChanged)
        self.navigationItem.title = "Folder"
        //self.folders = FolderViewController.foldersStatic
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return 1
        }
        if section == 2 {
            return 7
        }
        return folders.count <= 0 ? 0 : folders.count - 1
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return 71
        }
        return 44
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell") as! FolderCell
        if indexPath.section == 0 {
            cell.folderName.text = "Inbox"
            cell.folderImage.image = #imageLiteral(resourceName: "Inbox")
        }
        else if indexPath.section == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "folderListCell") as? FolderListCell{
            if indexPath.row == 0 {
                cell.body.text = "Hallo, das ist ein Fülltext"
                cell.from.text = "Jakob Bode"
                cell.from.font = UIFont.boldSystemFont(ofSize: 17)
                cell.subject.text = "Test-Subject"
                cell.secureImageView.image = IconsStyleKit.imageOfLetter
                cell.date.text = "13:47"
                cell.replyImageView.image = "↩️".image()
                
            }
            else if indexPath.row == 1 {
                cell.body.text = "Hallo, das ist ein Fülltext blah blah blah"
                cell.from.text = "Hans-Jörg"
                cell.from.font = UIFont.boldSystemFont(ofSize: 17)
                cell.subject.text = "Der Klassiker"
                cell.subject.font = UIFont.boldSystemFont(ofSize: cell.subject.font.pointSize)
                cell.body.font = UIFont.boldSystemFont(ofSize: cell.body.font.pointSize)
                cell.secureImageView.image = IconsStyleKit.imageOfLetter
                cell.date.text = "gestern"
                cell.markImageView.image = "🔵".image()
                
            }
            else {
                cell.body.text = "Hallo, das ist ein Fülltext"
                cell.from.text = "Jakob Bode"
                cell.from.font = UIFont.boldSystemFont(ofSize: 17)
                cell.subject.text = "Test-Subject"
                cell.secureImageView.image = IconsStyleKit.imageOfPostcard
                cell.date.text = "13:47"
                cell.replyImageView.image = "↩️".image()
                cell.markImageView.image = "🔵".image()
            }
            
            if cell.markImageView.image == nil {
                cell.stackView.removeArrangedSubview(cell.markImageView)
                cell.markImageView.removeFromSuperview()
            }
            
            if cell.replyImageView.image == nil {
                cell.stackView.removeArrangedSubview(cell.replyImageView)
                cell.replyImageView.removeFromSuperview()
            }
            
            return cell
            }
        }
        else if indexPath.row+1 < folders.count {
            cell.folderName.text = folders[indexPath.row+1]
            cell.folderImage.image = getImage(for: folders[indexPath.row+1])
        }
            
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "showInboxSegue", sender: nil)
        }
        else {
            if indexPath.row == 0 {
                let vc = storyboard?.instantiateViewController(withIdentifier: "folderViewController") as! FolderViewController
                vc.folders = ["abc", "test", "glsdkjd"]
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                performSegue(withIdentifier: "showFolderListSegue", sender: nil)
            }
        }
    }
    
    func refresh() {
        self.refreshControl?.endRefreshing()
    }
    
    func getImage(for name: String) -> UIImage {
        if false /*folders*/ {
            return #imageLiteral(resourceName: "Inbox")
        }
        return #imageLiteral(resourceName: "Inbox")
    }
}
