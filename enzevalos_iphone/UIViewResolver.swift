//
//  UIViewResolver.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 02.11.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit

enum UIViewResolver : Int {
    case unknown=0, cancel, imageView, send, toText, toCollectionview, ccText, ccCollectionview, subjectText, textView, tableview, scrollview
    
    internal static func resolve(_ tag : Int) -> String{
        if let ui = UIViewResolver(rawValue: tag) {
            return String(describing: ui)
        }
        return ""
    }
}

