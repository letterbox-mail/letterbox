//
//  OnboardingViewCells.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 21.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

public class SwitchCell : UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var switcher: UISwitch!
}

class InputCell : UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textfield: UITextField!
}
