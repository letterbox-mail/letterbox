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


public protocol Contact {
    var name: String { get }
    var cnContact: CNContact? { get }
    func getMailAddresses() -> [MailAddress]
}

extension Contact {
    private func makeImageFromName(_ name: String) -> UIImage {
        var text: NSAttributedString
        var tag = String()
        if name.characters.count > 0 {
            let seperated = name.components(separatedBy: " ")
            tag = seperated.map({if let a = $0.characters.first { return "\(a)" }; return "" }).joined()
        }

        text = NSAttributedString(string: tag.uppercased(), attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.systemFont(ofSize: 32.2)])

        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, false, 2) //try 200 here

        let context = UIGraphicsGetCurrentContext()

        //
        // Clip context to a circle
        //
        let path = CGPath(ellipseIn: myBounds, transform: nil);
        context!.addPath(path);
        context!.clip();

        //
        // Fill background of context
        //
        context!.setFillColor(self.getColor().cgColor)
        context!.fill(CGRect(x: 0, y: 0, width: myBounds.size.width, height: myBounds.size.height));


        //
        // Draw text in the context
        //
        let textSize = text.size()

        text.draw(in: CGRect(x: myBounds.size.width / 2 - textSize.width / 2, y: myBounds.size.height / 2 - textSize.height / 2, width: textSize.width, height: textSize.height))


        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return snapshot!

    }

    func getImageOrDefault() -> UIImage {
        if let contact = cnContact {
            if (contact.thumbnailImageData != nil) {
                return UIImage(data: contact.thumbnailImageData!)!
            }
        }
        return makeImageFromName(self.name)
    }

    func getColor() -> UIColor {
        
        if let enzCon = self as? EnzevalosContact {
            if let color = enzCon.color {
                return color
            }
            
            //let red = CGFloat(arc4random_uniform(8))
            //let green = CGFloat(arc4random_uniform(8))
            //let blue = CGFloat(arc4random_uniform(8))
            let random = Int(arc4random_uniform(UInt32(ColorManager.colors.count)))
            
            
            let color = ColorManager.colors[random] //UIColor.init(red: red/10.0+0.2, green: green/10.0+0.2, blue: blue/10.0+0.2, alpha: 1)
            enzCon.color = color
            return color
        }
        // Overflow?!
        let prim: Int
        prim = 653

        let hash = (abs(self.name.hash)) % prim
        return UIColor(hue: CGFloat(hash) / CGFloat(prim), saturation: 1, brightness: 0.75, alpha: 1)
    }
}
