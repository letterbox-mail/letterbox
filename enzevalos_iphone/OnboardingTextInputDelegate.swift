//
//  OnboardingTextInputDelegate.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

protocol OnboardingTextInputDelegate: class {
    func nextButtonTapped(viewController: OnboardingTextInputViewController)
    func leftKeyboardButton(viewController: OnboardingTextInputViewController)
    func rightKeyboardButton(viewController: OnboardingTextInputViewController)
}
