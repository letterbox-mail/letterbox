//
//  VENDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 29.07.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import VENTokenField

class VENDataDelegate : NSObject, VENTokenFieldDataSource , VENTokenFieldDelegate {
    
    var changeFunc : (VENTokenField -> Void) = {(_ : VENTokenField) -> Void in
        print ("hallo")
    }
    
    override init() {
        super.init()
    }
    
    init(changeFunc: (VENTokenField -> Void)){
        self.changeFunc = changeFunc
        super.init()
    }
    
    func tokenField(tokenField: VENTokenField, didChangeText text: String?) {
        print(tokenField.inputText())
        print(text)
        changeFunc(tokenField)
    }
   
    func tokenField(tokenField: VENTokenField, colorSchemeForTokenAtIndex index: UInt) -> UIColor {
        //if AddressHandler.proveAddress(tokenField.textTokens[Int(index)] as! NSString) {
        if AddressHandler.proveAddress(tokenField.mailTokens[Int(index)] as! NSString) {
            return UIColor.init(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
        }
        return UIColor.orangeColor()
    }
    
    func tokenFieldDidBeginEditing(tokenField: VENTokenField) {
        print("begin")
        print(numberOfTokensInTokenField(tokenField))
    }
    
    func tokenField(tokenField: VENTokenField, didEnterText text: String) {
        tokenField.textTokens.addObject(text.lowercaseString)
        if AddressHandler.inContacts(text) {
            //TODO Mailadresse aus Kontakt holen
        }
        else {
            tokenField.mailTokens.addObject(text)
        }
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenField(tokenField: VENTokenField, didEnterText text: String, mail email: String) {
        tokenField.textTokens.addObject(text)
        tokenField.mailTokens.addObject(email)
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenField(tokenField: VENTokenField, didDeleteTokenAtIndex index: UInt) {
        tokenField.textTokens.removeObjectAtIndex(Int(index))
        tokenField.mailTokens.removeObjectAtIndex(Int(index))
        tokenField.reloadData()
        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenField(tokenField: VENTokenField, titleForTokenAtIndex index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }
    
    func numberOfTokensInTokenField(tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }
    
    func tokenFieldCollapsedText(tokenField: VENTokenField) -> String {
        var text : String = "names: "
        text.appendContentsOf(String(tokenField.dataSource?.numberOfTokensInTokenField!(tokenField)))
        return text
    }
    
    func tokenField(tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        print("height: ",height)
        for c in tokenField.constraints {
            if (c.identifier == "tokenFieldHeight"){
                c.constant = height
                print("set height")
            }
        }
    }
    
    //eigene Methoden
    
    func tokenFieldDidEndEditing(tokenF: VENTokenField){
        print("end")
        if let last = tokenF.inputText() {
            if last.stringByReplacingOccurrencesOfString(" ", withString: "") != "" {
                tokenField(tokenF, didEnterText: last)
            }
        }
        
    }
    
    /*func tokenStrings(tokenField: VENTokenField) -> [String]{
        return tokenField.textTokens
    }*/
    
    func isSecure(tokenField: VENTokenField) -> Bool {
        var secure = true
        for entry in tokenField.mailTokens{
            secure = secure && AddressHandler.proveAddress(entry as! NSString)
        }
        return secure
    }
}
