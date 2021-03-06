//
//  SendViewController+Invitation.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
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

// MARK: - InvitationSelection

struct InvitationSelection {
    var selectedWords = Set<NSRange>()
    var code: String?
    var didShowDialog = false
}

// MARK: - SendViewController Extension

extension SendViewController {

    var isCensored: Bool {
        get {
            return StudySettings.invitationsmode == InvitationMode.Censorship
        }
    }

    func htmlMessage() -> (html: String?, textparts: Int, plaintext: String?) {
        var htmlName = "invitationText"
        if isCensored {
            htmlName = "invitationTextCensor"
        }
        guard
            let resource = Bundle.main.url(forResource: htmlName, withExtension: "html"),
            let data = try? Data(contentsOf: resource),
            let htmlString = String(data: data, encoding: .utf8), (self.isEligibleForInvitation() == true && self.invitationSelection.selectedWords.isEmpty == false) else {
                return (nil, 0, nil)
        }

        var text: String = self.textView.text
        var plainText: String = self.textView.text

        let textsToEncrypt = self.invitationSelection.selectedWords.sorted { (lhs, rhs) -> Bool in
            return lhs.location < rhs.location
        }.map { (range) -> String in
            return (text as NSString).substring(with: range)
        }
        let cipherText = SwiftPGP().symmetricEncrypt(textToEncrypt: [textsToEncrypt.joined(separator: "\n")], armored: true, password: nil)
        let texts = textsToEncrypt.map { _ -> String in
            // Change text in mail body
            if isCensored {
                return String(repeating: "█" as String as String, count: (Int(arc4random_uniform(7) + 3)))
            }
            return String.random(length: 10)
        }

        guard
            let urlTexts = texts.joined(separator: ",").urlString,
            let cipher = cipherText.chiphers.first?.urlString else {
                return (nil, 0, nil)
        }

        var link = "http://letterbox.imp.fu-berlin.de?text=\(urlTexts)&cipher=\(cipher)&id=\(StudySettings.studyID)&invitation=Enc"
        if isCensored {
            link = "http://letterbox.imp.fu-berlin.de?id=\(StudySettings.studyID)&invitation=Censor"
        }

        let locations = self.invitationSelection.selectedWords.sorted { (lhs, rhs) -> Bool in
            return rhs.location < lhs.location
        }

        for (index, range) in locations.enumerated() {
            if isCensored {
                let t = text as NSString
                text = t.replacingCharacters(in: range, with: texts[index])
                plainText = (plainText as NSString).replacingCharacters(in: range, with: texts[index])
            }
            else {
                text = (text as NSString).replacingCharacters(in: range, with: "<a class=\"encrypted-text\">\(texts[index])</a>")
                plainText = (plainText as NSString).replacingCharacters(in: range, with: texts[index])


            }
        }
        if (self.invitationSelection.code == nil && StudySettings.invitationsmode == InvitationMode.PasswordEnc) {
            self.invitationSelection.code = cipherText.password
        }
        var previousText = ""

        if let range = text.range(of: NSLocalizedString("Mail.Signature", comment: "")) {
            text.removeSubrange(range)
        }

        if let preMail = prefilledMail, let previousBody = preMail.body {
            if let range = text.range(of: previousBody) {
                previousText = previousBody
                text.removeSubrange(range)
            }
        }

        var plainFooter = String(format: NSLocalizedString("Invitation.EncryptionFooter", comment: ""), link, link)
        if isCensored {
            plainFooter = String(format: NSLocalizedString("Invitation.CensorFooter", comment: ""), link, link)
        }

        plainText = plainText + plainFooter + "\n\n" + previousText

        return (String(format: htmlString, text, link, link, previousText), texts.count, nil)
    }

    fileprivate func removeAllInvitationMarks() {
        if (self.invitationSelection.selectedWords.isEmpty == false) {
            self.invitationSelection.selectedWords = Set<NSRange>()
            self.layoutText()
        }
    }

    fileprivate func menuControllerItems(for textView: UITextView) -> [UIMenuItem]? {

        if (self.textView.selectedRange.location == 0 && self.textView.selectedRange.length == 0) {
            return nil
        }

        let selectedRange = self.invitationSelection.selectedWords.first { (range) -> Bool in
            return range.isInRange(of: self.textView.selectedRange)
        }

        guard selectedRange != nil else {
            let labelTitel: String
            switch StudySettings.invitationsmode {
            case .Censorship: labelTitel = NSLocalizedString("Invitation.Encrypt.Censor", comment: "")
            case .PasswordEnc: labelTitel = NSLocalizedString("Invitation.Encrypt", comment: "")
            case .FreeText,
                 .InviteMail: return nil
            }
            return [UIMenuItem(title: labelTitel, action: #selector(self.markSelectedText))]
        }
        let labelTitel: String
        switch StudySettings.invitationsmode {
        case .Censorship: labelTitel = NSLocalizedString("Invitation.Decrypt.Censor", comment: "")
        case .PasswordEnc: labelTitel = NSLocalizedString("Invitation.Decrypt", comment: "")
        case .FreeText,
             .InviteMail: return nil
        }
        return [UIMenuItem(title: labelTitel, action: #selector(self.unmarkSelectedText))]
    }

    fileprivate func layoutText() {

        let selectedRange = self.textView.selectedTextRange

        defer {
            self.textView.selectedTextRange = selectedRange
        }

        guard self.invitationSelection.selectedWords.isEmpty == false && self.isEligibleForInvitation() == true else {
            let attributedString = NSMutableAttributedString(string: self.textView.text)
            let fullRange = NSRange(location: 0, length: attributedString.string.count)
            attributedString.addAttributes([NSAttributedStringKey.font: self.textView.font], range: fullRange)
            attributedString.removeAttribute(NSAttributedStringKey.backgroundColor, range: fullRange)
            self.textView.attributedText = attributedString
            return
        }

        let text: String = self.textView.text
        let orangeColor = UIColor.Invitation.orange
        let attributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedStringKey.font: self.textView.font!])

        for range in self.invitationSelection.selectedWords {
            attributedString.addAttributes([NSAttributedStringKey.backgroundColor: orangeColor], range: range)
        }

        self.textView.attributedText = attributedString
    }

    fileprivate func addRange(_ rangeToAdd: NSRange) {

        let similarRange = self.invitationSelection.selectedWords.first { (range) -> Bool in
            return rangeToAdd.isInRange(of: range)
        }

        guard let range = similarRange else {
            self.invitationSelection.selectedWords.insert(rangeToAdd)
            return
        }

        self.invitationSelection.selectedWords.remove(range)
        self.invitationSelection.selectedWords.insert(range.union(rangeToAdd))
    }

    fileprivate func removeRange(_ rangeToRemove: NSRange) {

        let similarRange = self.invitationSelection.selectedWords.first { (range) -> Bool in
            return rangeToRemove.isInRange(of: range)
        }

        guard let range = similarRange else {
            return
        }

        self.invitationSelection.selectedWords.remove(range)
    }

    func showFirstDialogIfNeeded() {

        guard (self.isEligibleForInvitation() == true && self.invitationSelection.didShowDialog == false && InvitationUserDefaults.shouldNotShowFirstDialog.bool == false && invite == false) else {
            return
        }

        self.invitationSelection.didShowDialog = true
        let controller = DialogViewController.present(on: self, with: .invitationWelcome) { [weak self] in
            self?.view.endEditing(true)
        }

        controller?.ctaAction = {
            controller?.hideDialog(completion: nil)
            switch StudySettings.invitationsmode {
            case .FreeText:
                self.performSegue(withIdentifier: "inviteSegueStudy", sender: nil)
                return
            case .InviteMail:
                self.performSegue(withIdentifier: "inviteSegue", sender: nil)
                return
            case .Censorship, .PasswordEnc:
                return
            }
        }

        controller?.dismissAction = {
            InvitationUserDefaults.shouldNotShowFirstDialog.set(true)
        }
    }

    func showStepDialog() {

        guard (InvitationUserDefaults.shouldNotShowSecondDialog.bool == false) else {
            return
        }

        self.view.endEditing(true)
        InvitationUserDefaults.shouldNotShowSecondDialog.set(true)
        let controller = DialogViewController.present(on: self, with: .invitationStep)

        controller?.ctaAction = {
            controller?.hideDialog(completion: nil)
        }

        controller?.dismissAction = { [weak self] in
            self?.invitationSelection.selectedWords = Set<NSRange>()
            self?.layoutText()
        }
    }

    func showHelpDialog() {
        let controller = DialogViewController.present(on: self, with: .invitationHelp)

        controller?.ctaAction = {
            controller?.hideDialog(completion: nil)
        }
    }
}

// MARK: - MarkHandler

extension SendViewController {

    /// Whenever the marked Text changed, the Buttons for "encrypting" or "decrypting" will change there visibility.
    ///
    /// - Parameter textView: that changed it's selected Text
    func updateMarkedText(for textView: UITextView) {

        guard isEligibleForInvitation() else {
            removeAllInvitationMarks()
            return
        }

        UIMenuController.shared.menuItems = menuControllerItems(for: textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        UIMenuController.shared.menuItems = nil
    }

    /// Whenever text changes are made, the invitation Selection needs to be updated.
    /// Check for all stored Indexes, if changes are needed.
    ///
    /// - Parameters:
    ///   - range: where the Text Changed
    ///   - replacedText: that replaced the range
    fileprivate func textChanged(inRange range: NSRange, with replacedText: String) {

        let replacedTextLength = replacedText.count

        let selectedWords = self.invitationSelection.selectedWords
            .map({ (selectedRange) -> NSRange? in

                guard (selectedRange.location + selectedRange.length > range.location) else {
                    return selectedRange
                }

                guard (selectedRange.location <= range.location + range.length) else {
                    return NSRange(location: selectedRange.location - range.length + replacedTextLength, length: selectedRange.length)
                }

                return nil
            }).flatMap { $0 }

        self.invitationSelection.selectedWords = Set<NSRange>(selectedWords)
    }

    func textViewDidChange(_ textView: UITextView) {
        self.layoutText()
    }

    /// The Selected Text in the given TextView should be marked.
    /// Store starting Indexes in the Invitation Selection
    ///
    /// - Parameter textView
    @IBAction
    fileprivate func markSelectedText() {

        let wordsResult = self.textView.text.words(inRange: self.textView.selectedRange)

        if let range = wordsResult?.extendedRange {

            if (self.invitationSelection.selectedWords.isEmpty == true) {
                self.showStepDialog()
            }

            self.addRange(range)
            self.layoutText()
        }
    }

    /// The Selected Text in the given TextView should be unmarked.
    /// remove starting Indexes in the Invitation Selection
    ///
    /// - Parameter textView
    @IBAction
    fileprivate func unmarkSelectedText() {

        let wordsResult = self.textView.text.words(inRange: self.textView.selectedRange)

        if let range = wordsResult?.extendedRange {
            self.removeRange(range)
            self.layoutText()
        }
    }

    /// Should return true, if the current recipients are insecure
    ///
    /// - Returns: True if the current E-Mail is insecure
    fileprivate func isEligibleForInvitation() -> Bool {
        return (mailSecurityState != .letter && StudySettings.invitationEnabled)
    }
}

// MARK: - UITextViewDelegate

extension SendViewController: UITextViewDelegate {

    func textViewDidChangeSelection(_ textView: UITextView) {
        self.updateMarkedText(for: textView)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.updateMarkedText(for: textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        self.textChanged(inRange: range, with: text)
        return true
    }
}
