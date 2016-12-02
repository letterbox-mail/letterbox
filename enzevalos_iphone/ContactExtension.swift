//
//  ImageExtension.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 09.09.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import UIKit
import Contacts

extension CNContact {
    func getImageOrDefault() -> UIImage{
        if (self.thumbnailImageData != nil) {
            return UIImage(data : self.thumbnailImageData!)!
        }
        //let scale = UIScreen.mainScreen().scale
        var text : NSAttributedString
        if self.givenName.startIndex != self.givenName.endIndex && self.familyName.startIndex != self.familyName.endIndex {
            text = NSAttributedString(string: self.givenName.substringToIndex(self.givenName.startIndex.successor())+""+self.familyName.substringToIndex(self.familyName.startIndex.successor()), attributes: [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(32.2 /*UIFont.systemFontSize()*2.3*/)]) //string: self.givenName.substringToIndex()+""+self.familyName.substringToIndex(self.familyName.startIndex.successor()))
        }
        else if self.givenName.startIndex != self.givenName.endIndex {
            text = NSAttributedString(string: self.givenName.substringToIndex(self.givenName.startIndex.successor()), attributes: [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(32.2)])
        }
        else if self.familyName.startIndex != self.familyName.endIndex {
            text = NSAttributedString(string: self.familyName.substringToIndex(self.familyName.startIndex.successor()), attributes: [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(32.2)])
        }
        else {
            text = NSAttributedString(string: (self.emailAddresses.last?.value as! String).substringToIndex((self.emailAddresses.last?.value as! String).startIndex.successor()).capitalizedString, attributes: [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(32.2)])
        }
        //size.width = floorf(size.width * scale) / scale;
        //size.height = floorf(size.height * scale) / scale;
        
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
    
    func getColor() -> UIColor{
        // Overflow?!
        let hash = (abs((self.emailAddresses.first!.value as! String).hash)) % 653
        return UIColor(hue: CGFloat(hash) / CGFloat(653), saturation: 1, brightness: 0.75, alpha: 1)
    }
    
    func hasKey() -> Bool {
        let handler = KeyHandler.createHandler()
        for mail in self.emailAddresses {
            if handler.addrHasKey(mail.value as! String) {
                return true
            }
        }
        return false
    }
    
    //TODO check expiration date
    //TODO add ability to choose different keys
    func getKey() -> KeyWrapper? {
        let handler = KeyHandler.createHandler()
        for mail in self.emailAddresses {
            if handler.addrHasKey(mail.value as! String) {
                return handler.getKeyByAddr(mail.value as! String)
            }
        }
        return nil
    }
    
    func getKey(mailaddress: String) -> KeyWrapper? {
        let mail = mailaddress.lowercaseString
        let handler = KeyHandler.createHandler()
        return handler.getKeyByAddr(mail)
    }
    
    //TODO fertigmachen
    func addKey(key: PGPKey, mailaddress: String){
        let handler = KeyHandler.createHandler()
        //handler.addKeyForMailaddress(mailaddress, key: key)
    }
    
    func addPGPKey(key: KeyWrapper, mailaddress: String){
        let handler = KeyHandler.createHandler()
        handler.addKeyForMailaddress(mailaddress, keyWrapper: key)
    }
}
