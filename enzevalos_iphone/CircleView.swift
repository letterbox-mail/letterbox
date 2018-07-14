//
//  CircleView.swift
//  enzevalos_iphone
//
//  Created by admin on 26.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

enum Direction {
    case Up
    case Down
    case Both
    case None
}


/**
 Displays the backgroundline for a subbadge. 

 Direction of line can be specified with variable drawTop : Direction (.Up .Down . Both)
 
 Color may be Changed via pathColor, if nil Color is gray
 
 */
class CircleView: UIView {
    // MARK:- Variables
    /**
     specifies Direction of line. Values: Direction : (.Up .Down .Both)
     
     Default is .Down
     */
    var drawTop: Direction = .Down

    let width: CGFloat = 3.0 // change in ArrowView too


    /**
     Changes the Color with which the Line is drawn. Default is gray
     */
    var pathColor: UIColor?

    // MARK:- Functions

    override func draw(_ rect: CGRect) {

        let path = UIBezierPath()
        path.lineWidth = width


        switch drawTop {
        case .Both:
            path.move(to: CGPoint(x: self.frame.width / 2, y: 0))
            path.addLine(to: CGPoint(x: self.frame.width / 2, y: self.frame.height))

            break
        case .Down:
            path.move(to: CGPoint(x: self.frame.width / 2, y: self.frame.height / 2))
            path.addLine(to: CGPoint(x: self.frame.width / 2, y: self.frame.height))
            break
        case .Up:
            path.move(to: CGPoint(x: self.frame.width / 2, y: 0))
            path.addLine(to: CGPoint(x: self.frame.width / 2, y: self.frame.height / 2))
            break
        case .None:
            break
        }


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
