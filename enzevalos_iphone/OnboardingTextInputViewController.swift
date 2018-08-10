//
//  OnboardingTextInputViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 10.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingTextInputViewController: UIViewController {
    
    @IBOutlet weak var labelTop: UILabel!
    @IBOutlet weak var textFieldTop: UITextField!
    @IBOutlet weak var underlineTop: UIView!
    @IBOutlet weak var labelBottom: UILabel!
    @IBOutlet weak var textFieldBottom: UITextField!
    @IBOutlet weak var underlineBottom: UIView!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet weak var underLabelTopPadding: NSLayoutConstraint!
    @IBOutlet weak var underTextFieldTopPadding: NSLayoutConstraint!
    @IBOutlet weak var sectionSpace: NSLayoutConstraint!
    @IBOutlet weak var underLabelBottomPadding: NSLayoutConstraint!
    @IBOutlet weak var underTextFieldBottomPadding: NSLayoutConstraint!
    @IBOutlet weak var underNextButtonPadding: NSLayoutConstraint!
    @IBOutlet weak var underlineTopHeight: NSLayoutConstraint!
    @IBOutlet weak var underlineBottomHeight: NSLayoutConstraint!
    
    var underLabelPadding: CGFloat {
        get {
            return underLabelTopPadding.constant
        }
        set(padding) {
            underLabelTopPadding.constant = padding
            underLabelBottomPadding.constant = padding
        }
    }
    
    var underTextFieldPadding: CGFloat {
        get {
            return underTextFieldTopPadding.constant
        }
        set(padding) {
            underTextFieldTopPadding.constant = padding
            underTextFieldBottomPadding.constant = padding
        }
    }
    
    var underlineHeight: CGFloat {
        get {
            return underlineTopHeight.constant
        }
        set(height) {
            underlineTopHeight.constant = height
            underlineBottomHeight.constant = height
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
    
    var viewModification: (() -> ())?
    var viewWillAppearBlock: (() -> ())?
    var viewWillDisappearBlock: (() -> ())?
    var layoutOptimization = true
    var disableSecondSection = false
    var disableButton = true
    var keyboardAccessoryLeft: String? = nil
    var keyboardAccessoryRight: Bool = true
    var defaultColor = UIColor.darkGray
    weak var textInputDelegate: OnboardingTextInputDelegate?
    weak var pageControlDelegate: OnboardingPageControlDelegate?
    
    override func viewDidLoad() {
        if textInputDelegate != nil {
            textFieldTop.delegate = textInputDelegate
            if !disableSecondSection {
                textFieldBottom.delegate = textInputDelegate
            }
        }
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
        underTextFieldPadding *= underTextFieldPadding/referenceSize
        topSpace.constant *= view.frame.height/referenceSize
        sectionSpace.constant *= view.frame.height/referenceSize
        nextButton.titleLabel?.font = nextButton.titleLabel?.font.withSize((nextButton.titleLabel?.font.pointSize)!*sqrt(view.frame.height/referenceSize)) 
        underlineHeight = 0.5
        if labelBottom.text == nil {
            underLabelBottomPadding.constant = 0
        }
        if disableSecondSection {
            textFieldBottom.removeFromSuperview()
            underlineBottom.removeFromSuperview()
        }
        if disableButton {
            nextButton.removeFromSuperview()
        }
        if keyboardAccessoryLeft != nil || keyboardAccessoryRight {
            let keyboardToolbar = UIToolbar()
            keyboardToolbar.sizeToFit()
            keyboardToolbar.barTintColor = defaultColor
            keyboardToolbar.backgroundColor = defaultColor
            var buttons: [UIBarButtonItem] = []
            if let left = keyboardAccessoryLeft {
                let leftBarButton = UIBarButtonItem(title: left, style: .plain, target: self, action: #selector(OnboardingTextInputViewController.leftKeyboardButtonAction))
                leftBarButton.tintColor = .orange
                buttons.append(leftBarButton)
            }
            let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            buttons.append(flexBarButton)
            if keyboardAccessoryRight {
                let rightBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(OnboardingTextInputViewController.rightKeyboardButtonAction))
                rightBarButton.tintColor = .orange
                buttons.append(rightBarButton)
            }
            keyboardToolbar.items = buttons
            textFieldTop.inputAccessoryView = keyboardToolbar
            textFieldBottom.inputAccessoryView = keyboardToolbar

        }
        labelFont = UIFont(descriptor: labelFont.fontDescriptor, size: 28*sqrt(view.frame.height/referenceSize))
    }
    
    @objc func leftKeyboardButtonAction() {
        if let delegate = textInputDelegate {
            delegate.leftKeyboardButton(viewController: self)
        }
    }
    
    @objc func rightKeyboardButtonAction() {
        if let delegate = textInputDelegate {
            delegate.rightKeyboardButton(viewController: self)
        }
    }
    
    @IBAction func nextButtonAction(_ sender: Any) {
        if let delegate = textInputDelegate {
            delegate.nextButtonTapped(viewController: self)
        }
    }
    
}
