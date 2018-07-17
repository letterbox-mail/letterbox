//
//  OnboardingConfirmationDelegate.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 17.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

protocol OnboardingConfirmationDelegate: class {
    func confirmationButtonTapped(viewController: OnboardingConfirmationViewController)
}
