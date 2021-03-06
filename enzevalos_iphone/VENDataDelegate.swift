//
//  VENDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 29.07.16.
//  //  This program is free software: you can redistribute it and/or modify
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

import VENTokenField

class VENDataDelegate: NSObject, VENTokenFieldDataSource, VENTokenFieldDelegate {

    var changeFunc: ((VENTokenField) -> Void) = { (_: VENTokenField) -> Void in }

    var beginFunc: ((VENTokenField) -> Void) = { (_: VENTokenField) -> Void in }

    var endFunc: ((VENTokenField) -> Void) = { (_: VENTokenField) -> Void in }

    var deleteFunc: (() -> Void) = { () -> Void in }

    var tappedWhenSelectedFunc: ((String) -> Void)? = nil

    var editing = false

    override init() {
        super.init()
    }

    init(changeFunc: @escaping ((VENTokenField) -> Void), tappedWhenSelectedFunc: ((String) -> Void)?, beginFunc: @escaping ((VENTokenField) -> Void), endFunc: @escaping ((VENTokenField) -> Void), deleteFunc: @escaping (() -> Void)) {
        self.changeFunc = changeFunc
        self.tappedWhenSelectedFunc = tappedWhenSelectedFunc
        self.deleteFunc = deleteFunc
        self.beginFunc = beginFunc
        self.endFunc = endFunc
        super.init()
    }

    func tokenField(_ tokenField: VENTokenField, didChangeText text: String?) {
        changeFunc(tokenField)
    }

    func tokenField(_ tokenField: VENTokenField, colorSchemeForTokenAt index: UInt) -> UIColor {
        let adr = tokenField.mailTokens[Int(index)] as! String
        var hasKey = false
        if let madr = DataHandler.handler.findMailAddress(adr: adr) {
            hasKey = madr.hasKey
        }
        if hasKey {
            return UIColor.init(red: 0, green: 122.0 / 255.0, blue: 1, alpha: 1)
        }
        return UIColor.orange
    }

    func tokenFieldDidBeginEditing(_ tokenField: VENTokenField) {
        if !editing {
            editing = true
            beginFunc(tokenField)
        }
    }

    func tokenField(_ tokenField: VENTokenField, didEnterText text: String) {
        let text = text.lowercased()
        tokenField.textTokens.add(text)
        tokenField.mailTokens.add(text)
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActions(for: UIControlEvents.editingDidEnd)
    }

    func tokenField(_ tokenField: VENTokenField, didEnterText text: String, mail email: String) {
        let email = email.lowercased()
        tokenField.textTokens.add(text)
        tokenField.mailTokens.add(email)
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActions(for: UIControlEvents.editingDidEnd)
    }

    func tokenField(_ tokenField: VENTokenField, didDeleteTokenAt index: UInt) {
        tokenField.textTokens.removeObject(at: Int(index))
        tokenField.mailTokens.removeObject(at: Int(index))
        tokenField.reloadData()
        deleteFunc()
        tokenField.sendActions(for: UIControlEvents.editingDidEnd)
    }

    func tokenField(_ tokenField: VENTokenField, titleForTokenAt index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }

    func numberOfTokens(in tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }

    func tokenFieldCollapsedText(_ tokenField: VENTokenField) -> String {
        var text: String = "names: "
        text.append(String(describing: tokenField.dataSource?.numberOfTokens!(in: tokenField)))
        return text
    }

    func tokenField(_ tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        for c in tokenField.constraints {
            if (c.identifier == "tokenFieldHeight") {
                c.constant = height
            }
        }
    }

    func tokenFieldDidEndEditing(_ tokenF: VENTokenField) {
        editing = false
        if let last = tokenF.inputText() {
            if last.replacingOccurrences(of: " ", with: "") != "" {
                tokenField(tokenF, didEnterText: last)
            }
        }
        endFunc(tokenF)
    }

    func tokenField(_ tokenField: VENTokenField, didTappedTokenTwice index: UInt) {
        if let fun = tappedWhenSelectedFunc {
            fun(tokenField.mailTokens[Int(index)] as! String)
        }
    }
}
