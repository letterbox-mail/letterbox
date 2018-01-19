//
//  InvitationHelper.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

extension String {

	/// Returns all Words (word is surrunded by whitespaces and newlines) within the given range
	///
	/// - Parameter range: range that includes all words that should be returned
	/// - Returns: all single words within the Range
	func words(inRange range: NSRange) -> [(word: String, index: Int)] {

		let strings = self.components(separatedBy: .whitespacesAndNewlines)
		var result = [(word: String, index: Int)]()

		var index = 0
		let start = range.location
		let length = range.length

		for string in strings {

			guard (index < start + length) else {
				break
			}

			guard (index + string.count >= start) else {
				index += (1 + string.count)
				continue
			}

			result.append((word: string, index: index))
			index += (1 + string.count)
		}

		return result.filter({ (word: String, index: Int) -> Bool in
			return (word.isEmpty == false)
		})
	}
}

extension UIView {

	func roundRect(_ radius: CGFloat) {
		self.layer.cornerRadius = radius
		self.layer.masksToBounds = true
	}

	func roundRect() {
		self.roundRect(self.frame.height / 2)
	}
}

extension UIColor {

	struct Invitation {

		static let gray 	= #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2392156863, alpha: 1)
		static let orange	= #colorLiteral(red: 1, green: 0.7058823529, blue: 0.2549019608, alpha: 1)
	}
}
