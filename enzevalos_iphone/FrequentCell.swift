//
//  FrequentCell.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 10.09.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import UIKit

class FrequentCell : UICollectionViewCell {
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var type: UIImageView!
    @IBOutlet weak var background: UIImageView!
    
    var address = ""
    var identifier = ""
    
    func drawBackgroud(color : UIColor){
        var myBounds = CGRect()
        myBounds.size.width = 70
        myBounds.size.height = 70
        UIGraphicsBeginImageContextWithOptions(myBounds.size, false, 2) //try 200 here
        
        let context = UIGraphicsGetCurrentContext()
        
        //
        // Clip context to a circle
        //
        let path = CGPathCreateWithEllipseInRect(myBounds, nil);
        CGContextAddPath(context, path);
        CGContextClip(context);
        
        
        //
        // Fill background of context
        //
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, CGRectMake(0, 0, myBounds.size.width, myBounds.size.height));
        
        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.background.image = snapshot
    }
    
}
