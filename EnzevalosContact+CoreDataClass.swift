//
//  EnzevalosContact+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import UIKit
import Contacts


//TODO: add CNContact

@objc(EnzevalosContact)
public class EnzevalosContact: NSManagedObject {
    
    func update(name: String){
        setDisplayName(name)
      //TODO Find address and update preferences
        
    }
    
    func addFromMail(fromMail: Mail){
        self.addToFrom(fromMail)
    }
    
    func addToMail(mail: Mail){
        self.addToTo(mail)
    }
    
    func addCCMail(mail: Mail){
       self.addToCC(mail)
    }
    func addBCCMail(mail: Mail){
        self.addToBCC(mail)
    }
    
    func setDisplayName(name: String){
        self.displayname = name
    }
    
    func getName()-> String{
        var name: String
        name = String()
        if let cnc = self.getContact(){
            if cnc.givenName.characters.count > 0 {
                name += cnc.givenName
            }
            if cnc.familyName.characters.count > 0 {
                if name.characters.count > 0 {
                    name += " "
                }
                name += cnc.familyName
            }
        }
        if name.characters.count == 0 {
            return displayname!
        }
        return name
    }
    
    
    // TODO: Sort Onetime!
    func getFromMails()-> [Mail]{
        var fromMails: [Mail]
        fromMails = self.from!.allObjects as! [Mail]
        fromMails.sortInPlace({$0 < $1})
        return fromMails
    }
    
    //TODO: FIX ME
    func getContact()->CNContact?{
        // TODO: Check if contact exists in address book
        //        let contactFromBook = AddressHandler.contactByEmail((mail.sender?.mailbox)!)
        //        if let con = contactFromBook {
        //            contacts.append(EnzevalosContact(contact: con, mails: [mail]))
        //            return
        //        }
        
        // New contact has to be added
        let con = CNMutableContact()
        let name = self.displayname
        if let n = name {
            let nameArray = n.characters.split(" ").map(String.init)
            switch nameArray.count {
            case 1:
                con.givenName = nameArray.first!
            case 2..<20: // who has more than two names?!
                con.givenName = nameArray.first!
                con.familyName = nameArray.last!
            default:
                con.givenName = "NO"
                con.familyName = "NAME"
            }
        }
        
        let adr: Mail_Address
        adr = self.addresses?.anyObject() as! Mail_Address
        con.emailAddresses.append(CNLabeledValue(label: adr.address, value: CNLabelHome))
        
        return con
    }
    
    func getAddress(address: String)-> Mail_Address?{
        //TODO: DB request???
        var addr: Mail_Address
        if addresses != nil {
            for obj in addresses! {
                addr = obj as! Mail_Address
                if(addr.address == address){
                    return addr
                }
        
            }
        }
        return nil
    }
    
    func getAddressByMCOAddress(mcoaddress: MCOAddress)-> Mail_Address?{
        return getAddress(mcoaddress.mailbox!)
    }
    
    
    
    func getMailAddresses()->[Mail_Address]{
       return self.addresses!.allObjects as! [Mail_Address]
    }
    
    

    
    
    private func makeImageFromName(name: String)->UIImage{
        var text : NSAttributedString
        text = NSAttributedString(string: name, attributes: [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(32.2)])
        
        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, false, 2) //try 200 here
        
        let context = UIGraphicsGetCurrentContext()
        
        //
        // Clip context to a circle
        //
        let path = CGPathCreateWithEllipseInRect(myBounds, nil);
        CGContextAddPath(context!, path);
        CGContextClip(context!);
        
        //
        // Fill background of context
        //
        CGContextSetFillColorWithColor(context!, self.getColor().CGColor)
        CGContextFillRect(context!, CGRectMake(0, 0, myBounds.size.width, myBounds.size.height));
        
        
        //
        // Draw text in the context
        //
        let textSize = text.size()
        
        text.drawInRect(CGRectMake(myBounds.size.width/2 - textSize.width/2, myBounds.size.height/2 - textSize.height/2,textSize.width, textSize.height))
        
        
        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return snapshot!
        
    }
    
    func getImageOrDefault() -> UIImage{
        if let contact = getContact(){
            if (contact.thumbnailImageData != nil) {
                return UIImage(data : contact.thumbnailImageData!)!
            }
        }
        return makeImageFromName(self.getName())
    }
    
    func getColor() -> UIColor{
        // Overflow?!
        let prim: Int
        prim = 653
        
        let hash = (abs(self.getName().hash)) % prim //TODO Why is mail Addresses?
        print(hash)
        return UIColor(hue: CGFloat(hash) / CGFloat(prim), saturation: 1, brightness: 0.75, alpha: 1)
    }
}
private func isEmpty(contact: EnzevalosContact)-> Bool{
    if(contact.getFromMails().count == 0){
        return true
    }
    return false

}

func ==(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs){
        return false
    }
    if isEmpty(rhs){
        return false
    }
    
    return lhs.getFromMails().first!.date == rhs.getFromMails().first!.date
}

func <(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs){
        return true
    }
    if isEmpty(rhs){
        return false
    }
    return lhs.getFromMails().first!.date > rhs.getFromMails().first!.date
}



