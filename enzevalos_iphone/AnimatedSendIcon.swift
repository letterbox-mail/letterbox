//
//  AnimatedSendIcon.swift
//  enzevalos_iphone
//
//  Created by Joscha on 23.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//
//  RezisingBehavior taken from PaintCode generated file

import Foundation
import UIKit

class AnimatedSendIcon: UIView {
    var isOnTop = false
    var square = UIImageView(image:IconsStyleKit.imageOfLetterBG)
    var square2 = UIImageView(image:IconsStyleKit.imageOfPostcardBG)
    let width = 100.0
    let height = 70.0
    let f = 0.8
    var size = CGSize()
    var sizeSmall = CGSize()
    let front = CGPoint(x: 30, y: 35)
    let back = CGPoint(x: 100, y: 15)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        
        let resizing: ResizingBehavior = .aspectFit
//        let context = UIGraphicsGetCurrentContext()!
//        //// Resize to Target Frame
//        CGContextSaveGState(context)
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 200, height: 110), target: CGRect(x: 40, y: -10, width: 113, height: 48))
//        CGContextTranslateCTM(context, resizedFrame.minX, resizedFrame.minY)
//        CGContextScaleCTM(context, resizedFrame.width / 200, resizedFrame.height / 110)
//        
//        self.view.transform = CGAffineTransformMakeScale(2, 2)
        
        self.transform = CGAffineTransform(scaleX: resizedFrame.width / 200, y: resizedFrame.height / 110)
        //        self = UIView(frame: frame) //UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 110))
        self.backgroundColor = UIColor.white
        
        size = CGSize(width: width, height: height)
        sizeSmall = CGSize(width: width*f, height: height*f)
        
        square.frame = CGRect(origin: front, size: size)
        square2.frame = CGRect(origin: back, size: sizeSmall)
        square2.layer.zPosition = 0.0
        square2.alpha = 0.6
        square.layer.zPosition = 1.0
        
        
        self.addSubview(square)
        self.addSubview(square2)
        
//        CGContextRestoreGState(context)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func switchIcons() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.001 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            print("zPosition") // TODO: In swift 3, the layer switch seems to work, remove this then
            self.square.layer.zPosition = self.isOnTop ? 1 : 0
            self.square2.layer.zPosition = !self.isOnTop ? 1 : 0
            self.isOnTop = !self.isOnTop
        })
        
        if !isOnTop {
            UIView.animateKeyframes(withDuration: 0.75, delay: 0, options: .calculationModeCubicPaced, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                    self.square.frame = CGRect(x: 10, y: 20, width: self.width*0.95, height: self.height*0.95)
                    self.square2.frame = CGRect(x: 120, y: 20, width: self.width*0.85, height: self.height*0.85)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5, animations: {
                    self.square.frame = CGRect(x: 70, y: 5, width: self.width*0.78, height: self.height*0.78)
                    self.square.alpha = 0.6
                    self.square2.alpha = 1.0
                    self.square2.frame = CGRect(x: 60, y: 40, width: self.width*0.95, height: self.height*0.95)
                })
                
                UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25, animations: {
                    self.square.frame = CGRect(origin: self.back, size: self.sizeSmall)
                    self.square2.frame = CGRect(origin: self.front, size: self.size)
                })
                
                }, completion: nil)
        } else {
            UIView.animateKeyframes(withDuration: 0.75, delay: 0, options: .calculationModeCubicPaced, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25, animations: {
                    self.square2.frame = CGRect(x: 10, y: 20, width: self.width*0.95, height: self.height*0.95)
                    self.square.frame = CGRect(x: 120, y: 20, width: self.width*0.85, height: self.height*0.85)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5, animations: {
                    self.square2.frame = CGRect(x: 70, y: 5, width: self.width*0.85, height: self.height*0.85)
                    self.square2.alpha = 0.6
                    self.square.alpha = 1.0
                    self.square.frame = CGRect(x: 60, y: 40, width: self.width*0.95, height: self.height*0.95)
                })
                
                UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25, animations: {
                    self.square2.frame = CGRect(origin: self.back, size: self.sizeSmall)
                    self.square.frame = CGRect(origin: self.front, size: self.size)
                })
                
                }, completion: nil)
        }
    }
    
    @objc internal enum ResizingBehavior: Int {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.
        
        internal func apply(rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }
            
            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)
            
            switch self {
            case .aspectFit:
                scales.width = min(scales.width, scales.height)
                scales.height = scales.width
            case .aspectFill:
                scales.width = max(scales.width, scales.height)
                scales.height = scales.width
            case .stretch:
                break
            case .center:
                scales.width = 1
                scales.height = 1
            }
            
            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }
}
