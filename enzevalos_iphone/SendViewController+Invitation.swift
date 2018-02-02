//
//  SendViewController+Invitation.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

// MARK: - InvitationSelection

struct InvitationSelection {

	var selectedWords = Set<NSRange>()
}

// MARK: - SendViewController Extension

extension SendViewController {

	@IBAction
	fileprivate func encryptSelectedText() {

		self.invitationSelection.selectedWords.insert(self.textView.selectedRange)
		self.layoutText()
	}

	@IBAction
	fileprivate func decryptSelectedText() {

	}

	func layoutInvitationButton() {

	}

	func htmlMessage() -> String? {

		guard
			let resource = Bundle.main.url(forResource: "invitationText", withExtension: "html"),
			let data = try? Data(contentsOf: resource),
			let htmlString = String(data: data, encoding: .utf8) else {
				return self.textView.text
		}

		return String(format: htmlString, self.textView.text, "google.com")
	}

	fileprivate func removeAllInvitationMarks() {
		self.invitationSelection.selectedWords = Set<NSRange>()
		self.layoutText()
	}

	fileprivate func menuControllerItems(for textView: UITextView) -> [UIMenuItem]? {
		return [
			UIMenuItem(title: "verschlüsseln", action: #selector(self.encryptSelectedText)),
			UIMenuItem(title: "entschlüsseln", action: #selector(self.decryptSelectedText))
		]
	}

	fileprivate func layoutText() {

		guard self.invitationSelection.selectedWords.isEmpty == false else {
			self.textView.text = self.textView.attributedText.string
			return
		}

		let selectedRange = self.textView.selectedRange
		let text: String = self.textView.text
		let orangeColor = #colorLiteral(red: 1, green: 0.570499897, blue: 0, alpha: 1)
		let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: self.textView.font!])

		for range in self.invitationSelection.selectedWords {
			attributedString.addAttributes([NSBackgroundColorAttributeName : orangeColor], range: range)
		}

		self.textView.attributedText = attributedString
		self.textView.selectedRange = NSRange(location: selectedRange.location, length: 0)
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

	/// Whenever text changes are made, the invitation Selection needs to be updated.
	/// Check for all stored Indexes, if changes are needed.
	///
	/// - Parameters:
	///   - range: where the Text Changed
	///   - replacedText: that replaced the range
	fileprivate func textChanged(inRange range: NSRange, with replacedText: String) {
		let text = self.textView.text as String
		let words = text.words(inRange: range)
		let replacedTextLength = replacedText.count

		self.invitationSelection.selectedWords.forEach { (range) in

		}
	}

	/// The Selected Text in the given TextView should be marked.
	/// Store starting Indexes in the Invitation Selection
	///
	/// - Parameter textView
	fileprivate func markSelectedText(for textView: UITextView) {

	}

	/// The Selected Text in the given TextView should be unmarked.
	/// remove starting Indexes in the Invitation Selection
	///
	/// - Parameter textView
	fileprivate func unmarkSelectedText(for textView: UITextView) {

	}

	/// Should return true, if the current recipients are insecure
	///
	/// - Returns: True if the current E-Mail is insecure
	fileprivate func isEligibleForInvitation() -> Bool {
		return (self.toSecure == false)
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

// MARK: - IBAction

extension SendViewController {

	@IBAction private func unmarkTapped(sender: Any?) {

		self.unmarkSelectedText(for: self.textView)
	}

	@IBAction private func markTapped(sender: Any?) {

		self.markSelectedText(for: self.textView)
	}
}
