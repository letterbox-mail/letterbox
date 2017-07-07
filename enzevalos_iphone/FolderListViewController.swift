//
//  FolderListViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 07.07.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class FolderListViewController: UITableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderListCell") as! FolderListCell
        
        cell.body.text = "Hallo, das ist ein Fülltext"
        cell.from.text = "Jakob Bode"
//        cell.body.font = UIFont.init(name: cell.body.font.fontName, size: 20)
        cell.from.font = UIFont.boldSystemFont(ofSize: 17)
        cell.subject.text = "Test-Subject"
        cell.secureImageView.image = IconsStyleKit.imageOfLetter
        cell.date.text = "13:47"
        cell.replyImageView.image = "↩️".image()
        cell.markImageView.image = "🔵".image()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "readFolderMailSegue", sender: nil)
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
