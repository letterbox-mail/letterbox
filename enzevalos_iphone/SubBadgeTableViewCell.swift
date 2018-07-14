//
//  SubBadgeTableViewCell.swift
//  enzevalos_iphone
//
//  Created by admin on 26.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class SubBadgeTableViewCell: UITableViewCell {


    /**
     View Displaying the connecting line
     */
    @IBOutlet weak var lines: CircleView!

    /**
     name of the displayed Badge
     */
    @IBOutlet weak var badgeText: UILabel!

    /**
     Displayed Badge 
     */
    @IBOutlet weak var badgeImage: UIImageView!



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
