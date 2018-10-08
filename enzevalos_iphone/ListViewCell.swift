//
//  ListViewCell.swift
//  enzevalos_iphone
//
//  Created by Joscha on 04.10.16.
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
import Foundation

class ListViewCell: UITableViewCell {
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
}

class LoadingCell: UITableViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator.startAnimating()
    }
}
