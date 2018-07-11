//
//  OnboardingButtonInputViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingButtonInputViewController: UIViewController {
    
    @IBOutlet weak var labelTop: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet weak var underLabelTopPadding: NSLayoutConstraint!
    
    var underLabelPadding: CGFloat {
        get {
            return underLabelTopPadding.constant
        }
        set(padding) {
            underLabelTopPadding.constant = padding
        }
    }
    
    var buttonFont: UIFont? {
        get {
            if let label = leftButton.titleLabel {
                return label.font
            }
            return nil
        }
        set(font) {
            if leftButton.titleLabel != nil {
                leftButton.titleLabel?.font = font
            }
            if rightButton.titleLabel != nil {
                rightButton.titleLabel?.font = font
            }
        }
    }
    
    var foregroundColor: UIColor {
        get {
            return labelTop.tintColor
        }
        set(color) {
            labelTop.textColor = color
            if leftButton.titleLabel != nil {
                leftButton.titleLabel?.textColor = color
            }
            if rightButton.titleLabel != nil {
                rightButton.titleLabel?.textColor = color
            }
        }
    }
    
    var viewModification: (() -> ())?
    var viewWillAppearBlock: (() -> ())?
    var viewWillDisappearBlock: (() -> ())?
    var layoutOptimization = true
    weak var pageControlDelegate: OnboardingPageControlDelegate?
    weak var buttonInputDelegate: OnboardingButtonInputDelegate?
    
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
    
    @IBAction func leftButtonTapped(_ sender: Any) {
        if let delegate = buttonInputDelegate {
            delegate.leftButtonTapped()
        }
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
        if let delegate = buttonInputDelegate {
            delegate.rightButtonTapped()
        }
    }
    
    func optimizeLayout() {
        let referenceSize: CGFloat = 812.0
        underLabelPadding *= view.frame.height/referenceSize
        topSpace.constant *= view.frame.height/referenceSize
        //labelTop.font = UIFont(descriptor: labelTop.font.fontDescriptor, size: 38*sqrt(view.frame.height/referenceSize))
        buttonFont = UIFont(descriptor: labelTop.font.fontDescriptor, size: labelTop.font.pointSize*25/28)
        /*TODO: set selected color for buttons*/
    }
}
