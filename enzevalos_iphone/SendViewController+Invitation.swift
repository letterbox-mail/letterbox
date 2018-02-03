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
		let selectedRange = self.invitationSelection.selectedWords.first { (range) -> Bool in
			return range.isInRange(of: self.textView.selectedRange)
		}

		guard selectedRange != nil else {
			return [UIMenuItem(title: "verschlüsseln", action: #selector(self.markSelectedText))]
		}

		return [UIMenuItem(title: "entschlüsseln", action: #selector(self.unmarkSelectedText))]
	}

	fileprivate func layoutText() {

		let selectedRange = self.textView.selectedTextRange

		defer {
			self.textView.selectedTextRange = selectedRange
		}

		guard self.invitationSelection.selectedWords.isEmpty == false && self.isEligibleForInvitation() == true else {
			let attributedString = NSMutableAttributedString(attributedString: self.textView.attributedText)
			attributedString.removeAttribute(NSBackgroundColorAttributeName, range: NSRange(location: 0, length: attributedString.string.count))
			self.textView.attributedText = attributedString
			return
		}

		let text: String = self.textView.text
		let orangeColor = UIColor.Invitation.orange
		let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: self.textView.font!])

		for range in self.invitationSelection.selectedWords {
			attributedString.addAttributes([NSBackgroundColorAttributeName : orangeColor], range: range)
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
