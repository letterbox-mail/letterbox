//
//  SendViewController+Invitation.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

// MARK: - InvitationSelection


/*
 TODO:
 Code speichern (pro Kontakt)
 Erklärung was genau passiert?
 InviteMode == Enc || InviteMode == Censor -> Einladebutton wird zu Infobutton
 FreiText -> Popup -> leere E-Mail
*/
struct InvitationSelection {

    var selectedWords = Set<NSRange>()
    var code: String?
    var didShowDialog = false
}

// MARK: - SendViewController Extension

extension SendViewController {

    var isCensored: Bool{
        get{
            return StudySettings.invitationsmode == InvitationMode.Censorship
        }
    }
    
    func htmlMessage() -> String? {

        guard
            let resource = Bundle.main.url(forResource: "invitationText", withExtension: "html"),
            let data = try? Data(contentsOf: resource),
            let htmlString = String(data: data, encoding: .utf8), (self.isEligibleForInvitation() == true && self.invitationSelection.selectedWords.isEmpty == false) else {
                return nil
        }

        var text: String = self.textView.text
        let textsToEncrypt = self.invitationSelection.selectedWords.sorted { (lhs, rhs) -> Bool in
            return lhs.location < rhs.location
        }.map { (range) -> String in
            return (text as NSString).substring(with: range)
        }
        let cipherText = SwiftPGP().symmetricEncrypt(textToEncrypt: [textsToEncrypt.joined(separator: "\n")], armored: true, password: nil)
        let texts = textsToEncrypt.map { _ -> String in
            // Change text in mail body
            if isCensored{
                return String(repeating: "█" as String as String, count: (Int(arc4random_uniform(7)+3)))
            }
            return String.random(length: 10)
        }
        
        if texts.count > 0 {
            if isCensored {
                isCensoredMail = true
            }
            else{
                isPartialEncryptedMail = true
            }
        }

        guard
            let urlTexts = texts.joined(separator: ",").urlString,
            let cipher = cipherText.chiphers.first?.urlString else {
                return nil
        }

        var link = "http://enzevalos.konstantindeichmann.de?text=\(urlTexts)&cipher=\(cipher)"
        if isCensored{
            link = "https://userpage.fu-berlin.de/wieseoli/letterbox/"
        }

        let locations = self.invitationSelection.selectedWords.sorted { (lhs, rhs) -> Bool in
            return rhs.location < lhs.location
        }

        for (index, range) in locations.enumerated() {
            if isCensored{
                let t = text as NSString
                text = t.replacingCharacters(in: range, with: texts[index])
                text = text + NSLocalizedString("Invitation.CensorFooter", comment: "")
            }
            else{
                text = (text as NSString).replacingCharacters(in: range, with: "<a class=\"encrypted-text\">\(texts[index])</a>")
                
            }
        }
        if (self.invitationSelection.code == nil && StudySettings.invitationsmode == InvitationMode.PasswordEnc) {
            self.invitationSelection.code = cipherText.password
        }
        if StudySettings.invitationsmode == InvitationMode.Censorship{
            return text
            
        }
        return String(format: htmlString, text, link, link)
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
                case .Censorship    : labelTitel = NSLocalizedString("Invitation.Encrypt.Censor", comment: "")
                case .PasswordEnc   : labelTitel = NSLocalizedString("Invitation.Encrypt", comment: "")
                case .FreeText,
                     .InviteMail    : return nil
            }
            return [UIMenuItem(title: labelTitel, action: #selector(self.markSelectedText))]
        }
        let labelTitel: String
        switch StudySettings.invitationsmode {
        case .Censorship    : labelTitel = NSLocalizedString("Invitation.Decrypt.Censor", comment: "")
        case .PasswordEnc   : labelTitel = NSLocalizedString("Invitation.Decrypt", comment: "")
        case .FreeText,
             .InviteMail    : return nil
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
            attributedString.addAttributes([NSFontAttributeName: self.textView.font], range: fullRange)
            attributedString.removeAttribute(NSBackgroundColorAttributeName, range: fullRange)
            self.textView.attributedText = attributedString
            return
        }

        let text: String = self.textView.text
        let orangeColor = UIColor.Invitation.orange
        let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: self.textView.font!])

        for range in self.invitationSelection.selectedWords {
            attributedString.addAttributes([NSBackgroundColorAttributeName: orangeColor], range: range)
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

        guard (self.isEligibleForInvitation() == true) else {
            self.removeAllInvitationMarks()
            return
        }

        UIMenuController.shared.menuItems = self.menuControllerItems(for: textView)
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
        return (self.toSecure == false && StudySettings.invitationEnabled == true)
    }
}

// MARK: - UITextViewDelegate

extension SendViewController: UITextViewDelegate {

    func textViewDidChangeSelection(_ textView: UITextView) {
        self.updateMarkedText(for: textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        self.textChanged(inRange: range, with: text)
        return true
    }
}
