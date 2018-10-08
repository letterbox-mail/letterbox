//
//  Contact.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
        if name.count > 0 {
            let seperated = name.components(separatedBy: " ")
            tag = seperated.map({ if let a = $0.first { return "\(a)" }; return "" }).joined()
        }

        text = NSAttributedString(string: tag.uppercased(), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 32.2)])

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

            enzCon.color = UIColor(hue: CGFloat(arc4random()) / CGFloat(UINT32_MAX), saturation: 1, brightness: 0.75, alpha: 1)
            return enzCon.color!
        }
        // Overflow?!
        let prim = 653

        let hash = (abs(self.name.hash)) % prim
        return UIColor(hue: CGFloat(hash) / CGFloat(prim), saturation: 1, brightness: 0.75, alpha: 1)
    }
}
