//
//  UserNameGamificationTableViewCell.swift
//  enzevalos_iphone
//
//  Created by admin on 27.07.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class UserNameGamificationTableViewCell: UITableViewCell {



    @IBOutlet weak var userName: UILabel!

    @IBOutlet weak var mailLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
