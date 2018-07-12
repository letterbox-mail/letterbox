//
//  OnboardingSpinnerViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 12.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class OnboardingSpinnerViewController: UIViewController {
    
    @IBOutlet weak var labelTop: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
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
    
    var foregroundColor: UIColor {
        get {
            return labelTop.tintColor
        }
        set(color) {
            labelTop.textColor = color
            if spinner != nil {
                spinner.color = color
            }
        }
    }
    
    var viewModification: (() -> ())?
    var viewWillAppearBlock: (() -> ())?
    var viewWillDisappearBlock: (() -> ())?
    var layoutOptimization = true
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
        spinner.startAnimating()
        //labelTop.font = UIFont(descriptor: labelTop.font.fontDescriptor, size: 38*sqrt(view.frame.height/referenceSize))
    }
}
