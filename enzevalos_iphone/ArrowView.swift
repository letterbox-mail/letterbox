//
//  ArrowView.swift
//  enzevalos_iphone
//
//  Created by Moritz on 26.06.17.
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

import UIKit

/**
 Displays the line beetween two subbadges.

 Color may be Changed via pathColor, if nil Color is gray

 */
class ArrowView: UIView {
    // MARK:- Variables

    let width: CGFloat = 3.0 // change in CircleView too

    /**
     Changes the Color with which the Line is drawn. Default is gray
     */
    var pathColor: UIColor?


    // MARK:- Functions

    override func draw(_ rect: CGRect) {

        let path = UIBezierPath()
        path.lineWidth = width

        path.move(to: CGPoint(x: self.frame.width / 2, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width / 2, y: self.frame.height))

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
