//
//  TextFormatter.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 20.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

class TextFormatter {
    static func insertBeforeEveryLine(insertion: String, text: String) -> String{
        let textSep = text.componentsSeparatedByString("\n")
        var ret = ""
        for t in textSep {
            ret.appendContentsOf(insertion)
            ret.appendContentsOf(t)
            ret.appendContentsOf("\n")
        }
        return ret
    }
}
