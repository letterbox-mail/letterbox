//
//  SendViewDelegate.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 12.03.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

protocol SendViewDelegate {
    //called after composition
    func compositionDiscarded()
    func compositionSavedAsDraft()
    func compositionSent()
}
