//
//  ContactViewCell.swift
//  enzevalos_iphone
//
//  Created by Joscha on 16.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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
