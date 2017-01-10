//
//  Contact.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts
import UIKit


public protocol Contact { // TODO: Comparable??
    var name: String{get}
    var cnContact: CNContact? {get}
    func getMailAddresses()-> [MailAddress]
}
extension Contact{
    private func makeImageFromName(name: String)->UIImage{
        var text : NSAttributedString
        var tag:  String
        tag = String()
        if name.characters.count > 0 {
            tag = String(name.characters.first!)
        }
        
        
        text = NSAttributedString(string: tag.capitalizedString, attributes: [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(32.2)])
        
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
        if let contact = cnContact{
            if (contact.thumbnailImageData != nil) {
                return UIImage(data : contact.thumbnailImageData!)!
            }
        }
        return makeImageFromName(self.name)
    }
    
    func getColor() -> UIColor{
        // Overflow?!
        let prim: Int
        prim = 653
        
        let hash = (abs(self.name.hash)) % prim //TODO Why is mail Addresses?
        return UIColor(hue: CGFloat(hash) / CGFloat(prim), saturation: 1, brightness: 0.75, alpha: 1)
    }
}
