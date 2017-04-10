//
//  TextFormatter.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 20.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

class TextFormatter {
    static func insertBeforeEveryLine(_ insertion: String, text: String) -> String{
        let textSep = text.components(separatedBy: "\n")
        var ret = ""
        for t in textSep {
            ret.append(insertion)
            ret.append(t)
            ret.append("\n")
        }
        return ret
    }
}
