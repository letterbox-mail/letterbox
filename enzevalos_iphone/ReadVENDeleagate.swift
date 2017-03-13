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
    weak var tableView: UITableView?

    init(tappedWhenSelectedFunc: (String -> Void)? = nil, mailTokens: [String]? = nil, textTokens: [String]? = nil, tableView: UITableView? = nil) {
        self.tappedWhenSelectedFunc = tappedWhenSelectedFunc
        self.tableView = tableView
    }

    func tokenField(tokenField: VENTokenField, titleForTokenAtIndex index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }

    func numberOfTokensInTokenField(tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }

    func tokenFieldCollapsedText(tokenField: VENTokenField) -> String {
        if tokenField.textTokens.count > 1 {
            return "\(tokenField.textTokens.firstObject!) \(NSLocalizedString("and", comment: "and")) \(tokenField.textTokens.count - 1) \(NSLocalizedString("more", comment: "more"))"
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

    func tokenField(tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        if let tableView = tableView {
            let indexPath = NSIndexPath(forRow: 1, inSection: 0)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        }
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
        if EnzevalosEncryptionHandler.hasKey(DataHandler.handler.getContactByAddress(tokenField.mailTokens[Int(index)] as! String)) { //unfassbar langsam!
            return UIColor.init(red: 0, green: 122.0 / 255.0, blue: 1, alpha: 1)
        }
        return UIColor.orangeColor()
    }

    func tokenField(tokenField: VENTokenField, didTappedTokenTwice index: UInt) {
        if let fun = tappedWhenSelectedFunc {
            fun(tokenField.mailTokens[Int(index)] as! String)
        }
    }
}
