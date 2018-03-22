//
//  Theme.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 19/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit

let SelectedThemeKey = "security_indicator"
//var defaultColor = UIColor.groupTableViewBackgroundColor()
let defaultColor = ThemeManager.defaultColor

enum Theme: Int{
    /*
     Our themes: 
     No security indicators -> no different colors, symbols
     Weak security indicators -> different symbols but no color change
     Strong security indicators -> weak + different colors
     Very strong security indicators -> strong + animation
    */
   case no_security_indicator, weak_security_indicator, strong_security_indicator, very_strong_security_indicator
    
    
    var unencryptedMessageColor: UIColor{
        switch  self {
        case .no_security_indicator:
            return defaultColor
        case .weak_security_indicator:
                return defaultColor
        default:
            // orange
//            return UIColor(red: 247/255, green: 185/255, blue: 0/255, alpha: 1.0)
            return UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1.0)

        }
    }
    
    var encryptedMessageColor: UIColor{
        switch  self {
        case .no_security_indicator:
            return defaultColor
        case .weak_security_indicator:
            return defaultColor
        default:
            // green
//            return UIColor(red: 115/255, green: 229/255, blue: 105/255, alpha: 1.0)
            return UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
        }
    }
    
    var encryptedVerifiedMessageColor: UIColor{
        switch  self {
        case .no_security_indicator:
            return defaultColor
        case .weak_security_indicator:
            return defaultColor
        default:
            // green
            return UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
        }
    }
    
    var troubleMessageColor: UIColor{
        switch  self {
        case .no_security_indicator:
            return defaultColor
        case .weak_security_indicator:
            return defaultColor
        default:
            // red
//            return UIColor(red: 255/255, green: 99/255, blue: 99/255, alpha: 1.0)
            return UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0)
            
        }
    }
}


struct ThemeManager{
    static func currentTheme() -> Theme {
        if let storedTheme = (UserDefaults.standard.value(forKey: SelectedThemeKey) as? Int) {
            return Theme(rawValue: storedTheme)!
        } else {
            return .very_strong_security_indicator
        }
    }
    
    static func unencryptedMessageColor() -> UIColor{
        return currentTheme().unencryptedMessageColor
    
    }
    static func encryptedMessageColor() -> UIColor{
        return currentTheme().encryptedMessageColor
    }
    
    static func encryptedVerifiedMessageColor() -> UIColor{
        return currentTheme().encryptedVerifiedMessageColor
    }
    
    static func troubleMessageColor() -> UIColor{
        return currentTheme().troubleMessageColor
    }
    
    static func animation() -> Bool {
            return currentTheme() == .very_strong_security_indicator
    }
    
    static func applyTheme(_ theme: Theme) {
        UserDefaults.standard.setValue(theme.rawValue, forKey: SelectedThemeKey)
        UserDefaults.standard.synchronize()
    }
    
    static var defaultColor: UIColor = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.0)
}

