//
//  TableViewDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 01.09.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import VENTokenField
//import UIKit

class TableViewDataDelegate : NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var contacts : [String] = []
    var addresses : [String] = []
    var pictures : [UIImage?] = []
    //var count = 0
    //weak var tokenField : VENTokenField?
    var insertCallback : (String, String) -> Void = {(name : String, address : String) -> Void in return}
    
    init(insertCallback : (String, String) -> Void){
        self.insertCallback = insertCallback
        super.init()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("contacts") as! ContactCell
        cell.name.text = contacts[indexPath.row]
        cell.address.text = addresses[indexPath.row]
        cell.img.layer.cornerRadius = cell.img.frame.height/2
        cell.img.clipsToBounds = true
        cell.img.image = pictures[indexPath.row]
        if let img = pictures[indexPath.row] {
            cell.img.image = img
        }
        
        if (!AddressHandler.proveAddress(cell.address.text!)){
            //cell.backgroundColor = UIColor.orangeColor()
            cell.name.textColor! = UIColor.orangeColor()
            cell.address.textColor! = UIColor.orangeColor()
        }
        else {
            //cell.backgroundColor = nil
            cell.name.textColor! = UIColor.blackColor()
            cell.address.textColor! = UIColor.blackColor()
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /*if (tokenField != nil) {
            tokenField?.delegate?.tokenField!(tokenField!, didEnterText: contacts[indexPath.row], mail: addresses[indexPath.row])
        }*/
        self.insertCallback(contacts[indexPath.row], addresses[indexPath.row])
    }
    
    /*func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
    }*/
}
