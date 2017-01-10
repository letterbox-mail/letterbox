//
//  Record.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts
import UIKit


public protocol Record: Comparable {
    var name: String{get}
    var isSecure: Bool{get}
    var isVerified: Bool {get}
    func getContact()-> EnzevalosContact
    func getFromMails()->[Mail]
    func updateMails(mail:Mail)->Bool
    func getCNContact()-> CNContact?
}

extension Record {
    
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
        if let contact = getCNContact(){
            if (contact.thumbnailImageData != nil) {
                return UIImage(data : contact.thumbnailImageData!)!
            }
        }
        return makeImageFromName(self.name)
    }
    
    func getColor() -> UIColor{
        // Overflow?!
        let prim: Int
        prim = 11//653
    
        let hash = (abs(self.name.hash)) % prim //TODO Why is mail Addresses?
        print(hash)
        return UIColor(hue: CGFloat(hash) / CGFloat(prim), saturation: 1, brightness: 0.75, alpha: 1)
    }
    
    func hasKey() -> Bool {
        // TODO FIX ME
        // let handler = KeyHandler.getHandler()
        //for mail in self.emailAddresses {
          //  if handler.addrHasKey(mail.value as! String) {
            //    return true
            //}
        //}
        return false
    }
    
    //TODO check expiration date
    //TODO add ability to choose different keys
    func getKey() -> KeyWrapper? {
        //let handler = KeyHandler.getHandler()
      //  for mail in self.emailAddresses {
        //    if handler.addrHasKey(mail.value as! String) {
          //      return handler.getKeyByAddr(mail.value as! String)
            //}
        //}
        return nil
    }
    
    func getKey(mailaddress: String) -> KeyWrapper? {
        let mail = mailaddress.lowercaseString
        let handler = KeyHandler.getHandler()
        return handler.getKeyByAddr(mail)
    }
    
    //TODO fertigmachen
    func addKey(key: PGPKey, mailaddress: String){
        //let handler = KeyHandler.getHandler()
        //handler.addKeyForMailaddress(mailaddress, key: key)
    }
    
    func addPGPKey(key: KeyWrapper, mailaddress: String){
        let handler = KeyHandler.getHandler()
        handler.addKeyForMailaddress(mailaddress, keyWrapper: key)
    }
}

