//
//  ExportCells.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 05.10.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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
            secretRow1.text = secret.substring(to: cut1)
            secretRow2.text = secret.substring(with: cut1..<cut2)
            secretRow3.text = secret.substring(from: cut2)
        }
    }
    
}
