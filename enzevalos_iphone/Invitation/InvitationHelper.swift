//
//  InvitationHelper.swift
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

// MARK: - UserDefaults

enum InvitationUserDefaults: String {

    case shouldNotShowFirstDialog = "Invitation_shouldNotShowFirstDialog"
    case shouldNotShowSecondDialog = "Invitation_shouldNotShowSecondDialog"

    var bool: Bool {
        return UserDefaults.standard.bool(forKey: self.rawValue)
    }

    func set(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Extensions

extension String {

    func words(inRange range: NSRange) -> (words: String, extendedRange: NSRange)? {

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

        let string = result
            .map { (word, index) -> String in
                return word
            }.joined(separator: " ")

        guard let startIndex = result.first?.index else {
            return nil
        }

        let wordsRange = NSRange(location: startIndex, length: string.count)
        let words = (self as NSString).substring(with: wordsRange)

        return (words, wordsRange)
    }

    var urlString: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
}

extension NSRange {

    func isInRange(of range: NSRange) -> Bool {

        return self.contains(range.location) || range.contains(self.location)
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

        static let gray = #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2392156863, alpha: 1)
        static let orange = #colorLiteral(red: 1, green: 0.7058823529, blue: 0.2549019608, alpha: 1)
    }
}
