//
//  ReadVENDeleagate.swift
//  enzevalos_iphone
//
//  Created by Joscha on 10.03.17.
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

import Foundation
import VENTokenField

class ReadVENDelegate: NSObject, VENTokenFieldDataSource {
    var tappedWhenSelectedFunc: ((String) -> Void)? = nil
    weak var tableView: UITableView?

    init(tappedWhenSelectedFunc: ((String) -> Void)? = nil, mailTokens: [String]? = nil, textTokens: [String]? = nil, tableView: UITableView? = nil) {
        self.tappedWhenSelectedFunc = tappedWhenSelectedFunc
        self.tableView = tableView
    }

    func tokenField(_ tokenField: VENTokenField, titleForTokenAt index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }

    func numberOfTokens(in tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }

    func tokenFieldCollapsedText(_ tokenField: VENTokenField) -> String {
        if tokenField.textTokens.count > 1 {
            return "\(tokenField.textTokens.firstObject!) \(NSLocalizedString("and", comment: "and")) \(tokenField.textTokens.count - 1) \(NSLocalizedString("more", comment: "more"))"
        }
        return "\(tokenField.textTokens.firstObject ?? " ")"
    }
}

extension ReadVENDelegate: VENTokenFieldDelegate {
    func tokenField(_ tokenField: VENTokenField, didEnterText text: String) {
        tokenField.textTokens.add(text.lowercased())
    }

    func tokenField(_ tokenField: VENTokenField, didEnterText text: String, mail email: String) {
        tokenField.textTokens.add(text)
        tokenField.mailTokens.add(email)
        tokenField.reloadData()
//        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }

    func tokenField(_ tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        if let tableView = tableView {
            let indexPath = IndexPath(row: 1, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func tokenFieldDidEndEditing(_ tokenField: VENTokenField) {

    }

    func tokenField(_ tokenField: VENTokenField, didDeleteTokenAt index: UInt) {

    }

    func tokenField(_ tokenField: VENTokenField, didChangeText text: String?) {

    }

    func tokenFieldDidBeginEditing(_ tokenField: VENTokenField) {

    }

    func tokenField(_ tokenField: VENTokenField, colorSchemeForTokenAt index: UInt) -> UIColor {
        if let adr = DataHandler.handler.findMailAddress(adr: tokenField.mailTokens[Int(index)] as! String) {
            if adr.hasKey {
                return UIColor.init(red: 0, green: 122.0 / 255.0, blue: 1, alpha: 1)
            }
        }
        return UIColor.orange
    }

    func tokenField(_ tokenField: VENTokenField, didTappedTokenTwice index: UInt) {
        if let fun = tappedWhenSelectedFunc {
            fun(tokenField.mailTokens[Int(index)] as! String)
        }
    }
}

