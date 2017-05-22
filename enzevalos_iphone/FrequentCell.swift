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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = CGRect.init(x: 0, y: 0, width: 90, height: 100)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame = CGRect.init(x: 0, y: 33, width: 90, height: 100)
    }
    
    func drawBackgroud(_ color : UIColor){
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
        context!.setFillColor(color.cgColor)
        context!.fill(CGRect(x: 0, y: 0, width: myBounds.size.width, height: myBounds.size.height));
        
        let snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.background.image = snapshot
    }
    
}
