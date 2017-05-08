//
//  TableViewDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 01.09.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//


class TableViewDataDelegate : NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var contacts : [String] = []
    var addresses : [String] = []
    var pictures : [UIImage?] = []
    var insertCallback : (String, String) -> Void = {(name : String, address : String) -> Void in return}
    
    init(insertCallback : @escaping (String, String) -> Void){
        self.insertCallback = insertCallback
        super.init()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contacts") as! ContactCell
        cell.name.text = contacts[indexPath.row]
        cell.address.text = addresses[indexPath.row]
        cell.img.layer.cornerRadius = cell.img.frame.height/2
        cell.img.clipsToBounds = true
        cell.img.image = pictures[indexPath.row]
        if let img = pictures[indexPath.row] {
            cell.img.image = img
        }
        
        if !EnzevalosEncryptionHandler.hasKey(cell.address.text!) {
            cell.name.textColor! = UIColor.orange
            cell.address.textColor! = UIColor.orange
        }
        else {
            cell.name.textColor! = UIColor.black
            cell.address.textColor! = UIColor.black
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.insertCallback(contacts[indexPath.row], addresses[indexPath.row])
    }
    
}
