//
//  DescriptionView.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 27.06.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

@IBDesignable
class DescriptionView: UIView {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var underImagePadding: NSLayoutConstraint!
    @IBOutlet weak var underTitlePadding: NSLayoutConstraint!
    
    var contentView:UIView?
    @IBInspectable let nibName: String? = "DescriptionView"
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }*/
    
    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask =
            [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
        backgroundColor = UIColor.darkGray
    }
    
    func loadViewFromNib() -> UIView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(
            withOwner: self,
            options: nil).first as? UIView
    }
    
    /*override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }*/
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    func optimizeLayout() {
        imageHeightConstraint.constant = frame.height*70/667
        underImagePadding.constant = frame.height*30/667
        underTitlePadding.constant = frame.height*25/667
    }
    
}
