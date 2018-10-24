//
//  ContactViewCell.swift
//  enzevalos_iphone
//
//  Created by Joscha on 16.01.17.
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
import UIKit

class ContactViewCell: UITableViewCell {
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var contactStatus: UILabel!
}

class ActionCell: UITableViewCell {
    @IBOutlet weak var Button: UIButton!
}

class MailCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
}

class RecordCell: UITableViewCell {
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
}

class QRCodeCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var qrCode: UIImageView!
}

class ProgressCell: UITableViewCell {
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var firstProgress: UIProgressView!
    @IBOutlet weak var firstPercent: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var secondProgress: UIProgressView!
    @IBOutlet weak var secondPercent: UILabel!
}
