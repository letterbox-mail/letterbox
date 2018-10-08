//
//  subBadgeHeaderTableViewCell.swift
//  enzevalos_iphone
//
//  Created by Moritz on 26.06.17.
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

class SubBadgeHeaderTableViewCell: UITableViewCell {

    /**
     Displayed Badge
     */
    @IBOutlet weak var badgeImage: UIImageView!

    /**
     Displayed Headline
     */
    @IBOutlet weak var heaerLabel: UILabel!

    /**
     Dividing line beetween Header and following Views
     */
    @IBOutlet weak var bottomLine: UIView!


//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
