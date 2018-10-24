//
//  ExportCells.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 05.10.17.
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

class ExportInfoCell: UITableViewCell {
    @IBOutlet weak var infoTextLabel: UILabel!
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var qrCode: UIImageView!
}

class ExportEmailCell: UITableViewCell {
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
}

class ExportSendButtonCell: UITableViewCell {
    @IBOutlet weak var sendButton: UIButton!
}

class ExportSecretCell: UITableViewCell {
    @IBOutlet weak var infoTextLabel: UILabel!
    @IBOutlet weak var secretRow1: UILabel!
    @IBOutlet weak var secretRow2: UILabel!
    @IBOutlet weak var secretRow3: UILabel!

    func setSecretToLabels(secret: String) {
        if secret.count == 44 {
            let cut1 = secret.index(secret.startIndex, offsetBy: 15)
            let cut2 = secret.index(secret.startIndex, offsetBy: 30)
            secretRow1.text = String(secret[..<cut1])
            secretRow2.text = String(secret[cut1..<cut2])
            secretRow3.text = String(secret[cut2...])
        }
    }

}
