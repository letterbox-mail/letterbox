//
//  OnboardingPickerInputViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingPickerInputViewController: UIViewController {
    
    @IBOutlet weak var labelTop: UILabel!
    
    
    @IBOutlet weak var labelBottom: UILabel!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var pickerViewTop: UIPickerView!
    @IBOutlet weak var pickerViewBottom: UIPickerView!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet weak var underLabelTopPadding: NSLayoutConstraint!
    @IBOutlet weak var sectionSpace: NSLayoutConstraint!
    @IBOutlet weak var underLabelBottomPadding: NSLayoutConstraint!
    @IBOutlet weak var underNextButtonPadding: NSLayoutConstraint!
    
    var underLabelPadding: CGFloat {
        get {
            return underLabelTopPadding.constant
        }
        set(padding) {
            underLabelTopPadding.constant = padding
            underLabelBottomPadding.constant = padding
        }
    }
    
    var labelFont: UIFont {
        get {
            return labelTop.font
        }
        set(font) {
            labelTop.font = font
            labelBottom.font = font
        }
    }
    
    var pickerViewTintColor: UIColor {
        get {
            return pickerViewTop.tintColor
        }
        set(color) {
            pickerViewTop.tintColor = color
            pickerViewBottom.tintColor = color
        }
    }
    
    var viewModification: (() -> ())?
    var viewWillAppearBlock: (() -> ())?
    var viewWillDisappearBlock: (() -> ())?
    var layoutOptimization = true
    var disableSecondSection = false
    var disableButton = true
    weak var pageControlDelegate: OnboardingPageControlDelegate?
    
    override func viewDidLoad() {
        
        if let modification = viewModification {
            modification()
        }
        if layoutOptimization {
            optimizeLayout()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let block = viewWillAppearBlock {
            block()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let delegate = pageControlDelegate {
            delegate.contentViewControllerDidAppear(viewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let block = viewWillDisappearBlock {
            block()
        }
    }
    
    func optimizeLayout() {
        let referenceSize: CGFloat = 812.0
        underLabelPadding *= view.frame.height/referenceSize
        topSpace.constant *= view.frame.height/referenceSize
        nextButton.titleLabel?.font = nextButton.titleLabel?.font.withSize((nextButton.titleLabel?.font.pointSize)!*sqrt(view.frame.height/referenceSize))
        if labelBottom.text == nil {
            underLabelBottomPadding.constant = 0
        }
        if disableSecondSection {
            pickerViewBottom.removeFromSuperview()
            labelBottom.removeFromSuperview()
        }
        if disableButton {
            nextButton.removeFromSuperview()
        }
        labelFont = UIFont(descriptor: labelFont.fontDescriptor, size: 28*sqrt(view.frame.height/referenceSize))
    }
}
