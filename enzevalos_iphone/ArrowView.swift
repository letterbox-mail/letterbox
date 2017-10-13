//
//  ArrowView.swift
//  enzevalos_iphone
//
//  Created by admin on 26.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

/**
 Displays the line beetween two subbadges.

 Color may be Changed via pathColor, if nil Color is gray

 */
class ArrowView: UIView {
    // MARK:- Variables

    let width : CGFloat = 3.0 // change in CircleView too

    /**
     Changes the Color with which the Line is drawn. Default is gray
     */
    var pathColor : UIColor?


    // MARK:- Functions

    override func draw(_ rect: CGRect) {

        let path = UIBezierPath()
        path.lineWidth = width

        path.move(to: CGPoint(x: self.frame.width/2, y: 0 ))
        path.addLine(to: CGPoint(x: self.frame.width/2, y: self.frame.height ))

        path.close()

        if pathColor != nil {
            pathColor!.set()
        } else {
            UIColor.gray.set()
        }
        path.stroke()
        //path.fill()
    }


}
