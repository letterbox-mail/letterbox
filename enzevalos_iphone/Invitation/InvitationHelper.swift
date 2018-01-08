//
//  InvitationHelper.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

extension String {

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
