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
    
    var folders: [String] = []
    
    override func viewDidLoad() {
        self.refreshControl?.addTarget(self, action: #selector(FolderViewController.refresh), for: UIControlEvents.valueChanged)
        self.folders = FolderViewController.foldersStatic
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return 1
        }
        return folders.count <= 0 ? 0 : folders.count - 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell") as! FolderCell
        if indexPath.section == 0 {
            cell.folderName.text = "Inbox"
            cell.folderImage.image = #imageLiteral(resourceName: "Inbox")
        }
        else if indexPath.row+1 < folders.count {
            cell.folderName.text = folders[indexPath.row+1]
            cell.folderImage.image = getImage(for: folders[indexPath.row+1])
        }
            
        return cell
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
