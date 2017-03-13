//
//  ReadVENDeleagate.swift
//  enzevalos_iphone
//
//  Created by Joscha on 10.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import VENTokenField

class ReadVENDelegate: NSObject, VENTokenFieldDataSource {
    var tappedWhenSelectedFunc: (String -> Void)? = nil
    
    init(tappedWhenSelectedFunc: (String -> Void)? = nil, mailTokens: [String]? = nil, textTokens: [String]? = nil) {
        self.tappedWhenSelectedFunc = tappedWhenSelectedFunc
    }
    
    func tokenField(tokenField: VENTokenField, titleForTokenAtIndex index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }
    
    func numberOfTokensInTokenField(tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }
    
    func tokenFieldCollapsedText(tokenField: VENTokenField) -> String {
        if tokenField.textTokens.count > 1 {
            return "\(tokenField.textTokens.firstObject) +\(tokenField.textTokens.count-1)"
        }
        return "\(tokenField.textTokens.firstObject)"
    }
}

extension ReadVENDelegate: VENTokenFieldDelegate {
    func tokenField(tokenField: VENTokenField, didEnterText text: String) {
        tokenField.textTokens.addObject(text.lowercaseString)
    }
    
    func tokenField(tokenField: VENTokenField, didEnterText text: String, mail email: String) {
        tokenField.textTokens.addObject(text)
        tokenField.mailTokens.addObject(email)
        tokenField.reloadData()
//        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenFieldDidEndEditing(tokenField: VENTokenField) {
        
    }
    
    func tokenField(tokenField: VENTokenField, didDeleteTokenAtIndex index: UInt) {
        
    }
    
    func tokenField(tokenField: VENTokenField, didChangeText text: String?) {
        
    }
    
    func tokenFieldDidBeginEditing(tokenField: VENTokenField) {
        
    }
    
    func tokenField(tokenField: VENTokenField, colorSchemeForTokenAtIndex index: UInt) -> UIColor {
        return UIColor.orangeColor()
    }
    
    func tokenField(tokenField: VENTokenField, didTappedTokenTwice index: UInt){
        if let fun = tappedWhenSelectedFunc {
            fun(tokenField.mailTokens[Int(index)] as! String)
        }
    }
}
