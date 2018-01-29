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

	var selectedWords 	= Set<NSRange>()
	var showsButton		= false
}

// MARK: - SendViewController Extension

extension SendViewController {

	fileprivate func hideMarkButton() {

		guard (self.invitationSelection.showsButton == true) else {
			return
		}

		self.invitationSelection.showsButton = false
		self.scrollview.contentOffset.y -= 50
	}

	fileprivate func showMarkButton() {

		guard (self.invitationSelection.showsButton == false) else {
			return
		}

		self.invitationSelection.showsButton = true
		self.scrollview.contentOffset.y += 50
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

		return nil //String(format: htmlString, self.textView.text)
	}
}

// MARK: - MarkHandler

extension SendViewController {


	/// Whenever the marked Text changed, the Buttons for "encrypting" or "decrypting" will change there visibility.
	///
	/// - Parameter textView: that changed it's selected Text
	fileprivate func updateMarkedText(for textView: UITextView) {

		guard (textView.selectedRange.length != 0) else {
			self.hideMarkButton()
			return
		}

		self.showMarkButton()
	}

	/// Whenever text changes are made, the invitation Selection needs to be updated.
	/// Check for all stored Indexes, if changes are needed.
	///
	/// - Parameters:
	///   - range: where the Text Changed
	///   - replacedText: that replaced the range
	fileprivate func textChanged(inRange range: NSRange, with replacedText: String) {

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
}

// MARK: - TextViewDelegate

extension SendViewController {

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
