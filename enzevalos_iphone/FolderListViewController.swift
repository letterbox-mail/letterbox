//
//  FolderListViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 07.07.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class FolderListViewController: UITableViewController {
    
    var folder: Folder = Folder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = folder.name
        print("Hallo")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folder.mailsOfFolder.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderListCell") as! FolderListCell
        
        let mail = folder.mailsOfFolder.sorted()[indexPath.row]
        
        cell.body.text = mail.body
        if let contact = mail.from.contact {
            cell.from.text = contact.name
        }
        else {
            cell.from.text = mail.from.mailAddress
        }
        cell.subject.text = mail.subject
        cell.date.text = mail.timeString
        
        if mail.isSecure {
            cell.secureImageView.image = IconsStyleKit.imageOfLetter
        }
        else {
            cell.secureImageView.image = IconsStyleKit.imageOfPostcard
        }
        if !mail.flag.contains(MCOMessageFlag.seen) {
            cell.markImageView.image = "🔵".image()
            cell.body.font = UIFont.boldSystemFont(ofSize: cell.body.font.pointSize)
            cell.subject.font = UIFont.boldSystemFont(ofSize: cell.subject.font.pointSize)
        }
        if mail.flag.contains(MCOMessageFlag.answered) {
            cell.replyImageView.image = "↩️".image()
        }
        
        /*if indexPath.row == 0 {
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
        }*/
        
        if let markImageView = cell.markImageView {
            if markImageView.image == nil {
                cell.stackView.removeArrangedSubview(cell.markImageView)
            }
            else {
                cell.stackView.addArrangedSubview(cell.markImageView)
            }
            //cell.markImageView.removeFromSuperview()
        }
        
        
        if let replyImageView = cell.replyImageView {
            if replyImageView.image == nil {
                cell.stackView.removeArrangedSubview(cell.replyImageView)
            }
            else {
                cell.stackView.addArrangedSubview(cell.replyImageView)
            }
            //cell.replyImageView.removeFromSuperview()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "readFolderMailSegue", sender: folder.mailsOfFolder.sorted()[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "readFolderMailSegue" {
            let destinationVC = segue.destination as! ReadViewController
            if let mail = sender as? PersistentMail {
                destinationVC.mail = mail
            }
        }
    }
}

//inspired by https://stackoverflow.com/questions/38809425/convert-apple-emoji-string-to-uiimage
extension String {
    func image() -> UIImage {
        let size = CGSize(width: 30, height: 35)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        UIColor.white.set()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}
