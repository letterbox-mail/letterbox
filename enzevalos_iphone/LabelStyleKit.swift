////
//  LabelStyleKit.swift
//  enzevalos
//
//  Created by Joscha on 05.01.17.
//  Copyright © 2017 FU Berlin. All rights reserved.
//
//  Generated by PaintCode
//  http://www.paintcodeapp.com
//
//  This code was generated by Trial version of PaintCode, therefore cannot be used for commercial purposes.
//



import UIKit

public class LabelStyleKit : NSObject {

    //// Cache

    private struct Cache {
        static let black: UIColor = UIColor.blackColor()
        static var imageOfHome: UIImage?
        static var homeTargets: [AnyObject]?
        static var imageOfWork: UIImage?
        static var workTargets: [AnyObject]?
        static var imageOfOther: UIImage?
        static var otherTargets: [AnyObject]?
    }

    //// Colors

    public dynamic class var black: UIColor { return Cache.black }

    //// Drawing Methods

    public dynamic class func drawHome(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 28, height: 28), resizing: ResizingBehavior = .AspectFit, color: UIColor = LabelStyleKit.black) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        CGContextSaveGState(context)
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 28, height: 28), target: targetFrame)
        CGContextTranslateCTM(context, resizedFrame.minX, resizedFrame.minY)
        CGContextScaleCTM(context, resizedFrame.width / 28, resizedFrame.height / 28)


        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPoint(x: 21.2, y: 13))
        bezierPath.addLineToPoint(CGPoint(x: 7.1, y: 13))
        bezierPath.addCurveToPoint(CGPoint(x: 4.3, y: 15.8), controlPoint1: CGPoint(x: 5.5, y: 13), controlPoint2: CGPoint(x: 4.3, y: 14.3))
        bezierPath.addLineToPoint(CGPoint(x: 4.3, y: 24.6))
        bezierPath.addCurveToPoint(CGPoint(x: 7.1, y: 27.4), controlPoint1: CGPoint(x: 4.3, y: 26.2), controlPoint2: CGPoint(x: 5.6, y: 27.4))
        bezierPath.addLineToPoint(CGPoint(x: 21.2, y: 27.4))
        bezierPath.addCurveToPoint(CGPoint(x: 24, y: 24.6), controlPoint1: CGPoint(x: 22.8, y: 27.4), controlPoint2: CGPoint(x: 24, y: 26.1))
        bezierPath.addLineToPoint(CGPoint(x: 24, y: 15.8))
        bezierPath.addCurveToPoint(CGPoint(x: 21.2, y: 13), controlPoint1: CGPoint(x: 24.1, y: 14.3), controlPoint2: CGPoint(x: 22.8, y: 13))
        bezierPath.closePath()
        color.setFill()
        bezierPath.fill()


        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.moveToPoint(CGPoint(x: 14.3, y: 2.4))
        bezier2Path.addLineToPoint(CGPoint(x: 25.8, y: 14.2))
        bezier2Path.addLineToPoint(CGPoint(x: 2.5, y: 14.2))
        bezier2Path.addLineToPoint(CGPoint(x: 14.3, y: 2.4))
        bezier2Path.closePath()
        color.setFill()
        bezier2Path.fill()
        color.setStroke()
        bezier2Path.lineWidth = 3
        bezier2Path.lineJoinStyle = .Round
        bezier2Path.stroke()


        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.moveToPoint(CGPoint(x: 21.9, y: 10.6))
        bezier3Path.addLineToPoint(CGPoint(x: 20.8, y: 10.6))
        bezier3Path.addCurveToPoint(CGPoint(x: 19.9, y: 9.7), controlPoint1: CGPoint(x: 20.3, y: 10.6), controlPoint2: CGPoint(x: 19.9, y: 10.2))
        bezier3Path.addLineToPoint(CGPoint(x: 19.9, y: 4.7))
        bezier3Path.addCurveToPoint(CGPoint(x: 20.8, y: 3.8), controlPoint1: CGPoint(x: 19.9, y: 4.2), controlPoint2: CGPoint(x: 20.3, y: 3.8))
        bezier3Path.addLineToPoint(CGPoint(x: 21.9, y: 3.8))
        bezier3Path.addCurveToPoint(CGPoint(x: 22.8, y: 4.7), controlPoint1: CGPoint(x: 22.4, y: 3.8), controlPoint2: CGPoint(x: 22.8, y: 4.2))
        bezier3Path.addLineToPoint(CGPoint(x: 22.8, y: 9.8))
        bezier3Path.addCurveToPoint(CGPoint(x: 21.9, y: 10.6), controlPoint1: CGPoint(x: 22.7, y: 10.2), controlPoint2: CGPoint(x: 22.3, y: 10.6))
        bezier3Path.closePath()
        color.setFill()
        bezier3Path.fill()
        
        CGContextRestoreGState(context)

    }

    public dynamic class func drawWork(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 148, height: 134), resizing: ResizingBehavior = .AspectFit, color: UIColor = LabelStyleKit.black) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        CGContextSaveGState(context)
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 148, height: 134), target: targetFrame)
        CGContextTranslateCTM(context, resizedFrame.minX, resizedFrame.minY)
        CGContextScaleCTM(context, resizedFrame.width / 148, resizedFrame.height / 134)


        //// Bezier 3 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.moveToPoint(CGPoint(x: 79.9, y: 72.4))
        bezier3Path.addLineToPoint(CGPoint(x: 79.9, y: 76.5))
        bezier3Path.addCurveToPoint(CGPoint(x: 73.5, y: 82.9), controlPoint1: CGPoint(x: 79.9, y: 80), controlPoint2: CGPoint(x: 77, y: 82.9))
        bezier3Path.addLineToPoint(CGPoint(x: 73.5, y: 82.9))
        bezier3Path.addCurveToPoint(CGPoint(x: 67.1, y: 76.5), controlPoint1: CGPoint(x: 70, y: 82.9), controlPoint2: CGPoint(x: 67.1, y: 80))
        bezier3Path.addLineToPoint(CGPoint(x: 67.1, y: 72.2))
        bezier3Path.addCurveToPoint(CGPoint(x: 2.8, y: 63), controlPoint1: CGPoint(x: 29.8, y: 71), controlPoint2: CGPoint(x: 3.2, y: 63.2))
        bezier3Path.addLineToPoint(CGPoint(x: 2.8, y: 119))
        bezier3Path.addCurveToPoint(CGPoint(x: 14.8, y: 131), controlPoint1: CGPoint(x: 2.8, y: 125.6), controlPoint2: CGPoint(x: 8.2, y: 131))
        bezier3Path.addLineToPoint(CGPoint(x: 132.8, y: 131))
        bezier3Path.addCurveToPoint(CGPoint(x: 144.8, y: 119), controlPoint1: CGPoint(x: 139.4, y: 131), controlPoint2: CGPoint(x: 144.8, y: 125.6))
        bezier3Path.addLineToPoint(CGPoint(x: 144.8, y: 63))
        bezier3Path.addCurveToPoint(CGPoint(x: 79.9, y: 72.4), controlPoint1: CGPoint(x: 122.2, y: 69.9), controlPoint2: CGPoint(x: 100.3, y: 72.2))
        bezier3Path.closePath()
        color.setFill()
        bezier3Path.fill()


        //// Bezier 4 Drawing
        let bezier4Path = UIBezierPath()
        bezier4Path.moveToPoint(CGPoint(x: 132.8, y: 28.1))
        bezier4Path.addLineToPoint(CGPoint(x: 102.3, y: 28.1))
        bezier4Path.addLineToPoint(CGPoint(x: 102.3, y: 24.1))
        bezier4Path.addCurveToPoint(CGPoint(x: 81.9, y: 3.8), controlPoint1: CGPoint(x: 102.3, y: 12.9), controlPoint2: CGPoint(x: 93.2, y: 3.8))
        bezier4Path.addLineToPoint(CGPoint(x: 65.8, y: 3.8))
        bezier4Path.addCurveToPoint(CGPoint(x: 45.4, y: 24.1), controlPoint1: CGPoint(x: 54.6, y: 3.8), controlPoint2: CGPoint(x: 45.4, y: 12.9))
        bezier4Path.addLineToPoint(CGPoint(x: 45.4, y: 28.1))
        bezier4Path.addLineToPoint(CGPoint(x: 14.8, y: 28.1))
        bezier4Path.addCurveToPoint(CGPoint(x: 2.8, y: 40.1), controlPoint1: CGPoint(x: 8.2, y: 28.1), controlPoint2: CGPoint(x: 2.8, y: 33.5))
        bezier4Path.addLineToPoint(CGPoint(x: 2.8, y: 57.7))
        bezier4Path.addCurveToPoint(CGPoint(x: 67.1, y: 66.9), controlPoint1: CGPoint(x: 3.2, y: 57.8), controlPoint2: CGPoint(x: 30.3, y: 65.7))
        bezier4Path.addLineToPoint(CGPoint(x: 67.1, y: 63.6))
        bezier4Path.addCurveToPoint(CGPoint(x: 73.5, y: 57.2), controlPoint1: CGPoint(x: 67.1, y: 60.1), controlPoint2: CGPoint(x: 70, y: 57.2))
        bezier4Path.addLineToPoint(CGPoint(x: 73.5, y: 57.2))
        bezier4Path.addCurveToPoint(CGPoint(x: 79.9, y: 63.6), controlPoint1: CGPoint(x: 77, y: 57.2), controlPoint2: CGPoint(x: 79.9, y: 60.1))
        bezier4Path.addLineToPoint(CGPoint(x: 79.9, y: 67))
        bezier4Path.addCurveToPoint(CGPoint(x: 144.9, y: 57.6), controlPoint1: CGPoint(x: 100.2, y: 66.8), controlPoint2: CGPoint(x: 122.7, y: 64.4))
        bezier4Path.addLineToPoint(CGPoint(x: 144.9, y: 40.1))
        bezier4Path.addCurveToPoint(CGPoint(x: 132.8, y: 28.1), controlPoint1: CGPoint(x: 144.8, y: 33.5), controlPoint2: CGPoint(x: 139.5, y: 28.1))
        bezier4Path.closePath()
        bezier4Path.moveToPoint(CGPoint(x: 91.7, y: 28.1))
        bezier4Path.addLineToPoint(CGPoint(x: 56.1, y: 28.1))
        bezier4Path.addLineToPoint(CGPoint(x: 56.1, y: 24.1))
        bezier4Path.addCurveToPoint(CGPoint(x: 65.8, y: 14.4), controlPoint1: CGPoint(x: 56.1, y: 18.7), controlPoint2: CGPoint(x: 60.5, y: 14.4))
        bezier4Path.addLineToPoint(CGPoint(x: 82, y: 14.4))
        bezier4Path.addCurveToPoint(CGPoint(x: 91.7, y: 24.1), controlPoint1: CGPoint(x: 87.4, y: 14.4), controlPoint2: CGPoint(x: 91.7, y: 18.8))
        bezier4Path.addLineToPoint(CGPoint(x: 91.7, y: 28.1))
        bezier4Path.closePath()
        color.setFill()
        bezier4Path.fill()
        
        CGContextRestoreGState(context)

    }

    public dynamic class func drawOther(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 86, height: 82), resizing: ResizingBehavior = .AspectFit) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        CGContextSaveGState(context)
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 86, height: 82), target: targetFrame)
        CGContextTranslateCTM(context, resizedFrame.minX, resizedFrame.minY)
        CGContextScaleCTM(context, resizedFrame.width / 86, resizedFrame.height / 82)


        //// Star Drawing
        let starPath = UIBezierPath()
        starPath.moveToPoint(CGPoint(x: 43, y: 1))
        starPath.addLineToPoint(CGPoint(x: 55.19, y: 28.22))
        starPath.addLineToPoint(CGPoint(x: 84.85, y: 31.4))
        starPath.addLineToPoint(CGPoint(x: 62.73, y: 51.41))
        starPath.addLineToPoint(CGPoint(x: 68.86, y: 80.6))
        starPath.addLineToPoint(CGPoint(x: 43, y: 65.75))
        starPath.addLineToPoint(CGPoint(x: 17.14, y: 80.6))
        starPath.addLineToPoint(CGPoint(x: 23.27, y: 51.41))
        starPath.addLineToPoint(CGPoint(x: 1.15, y: 31.4))
        starPath.addLineToPoint(CGPoint(x: 30.81, y: 28.22))
        starPath.closePath()
        //color.setFill() TODO: ????
        starPath.fill()
        
        CGContextRestoreGState(context)

    }

    //// Generated Images

    public dynamic class var imageOfHome: UIImage {
        if Cache.imageOfHome != nil {
            return Cache.imageOfHome!
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 28, height: 28), false, 0)
            LabelStyleKit.drawHome()

        Cache.imageOfHome = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return Cache.imageOfHome!
    }

    public dynamic class var imageOfWork: UIImage {
        if Cache.imageOfWork != nil {
            return Cache.imageOfWork!
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 148, height: 134), false, 0)
            LabelStyleKit.drawWork()

        Cache.imageOfWork = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return Cache.imageOfWork!
    }

    public dynamic class var imageOfOther: UIImage {
        if Cache.imageOfOther != nil {
            return Cache.imageOfOther!
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 86, height: 82), false, 0)
            LabelStyleKit.drawOther()

        Cache.imageOfOther = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return Cache.imageOfOther!
    }

    //// Customization Infrastructure

    @IBOutlet dynamic var homeTargets: [AnyObject]! {
        get { return Cache.homeTargets }
        set {
            Cache.homeTargets = newValue
            for target: AnyObject in newValue {
                target.performSelector(NSSelectorFromString("setImage:"), withObject: LabelStyleKit.imageOfHome)
            }
        }
    }

    @IBOutlet dynamic var workTargets: [AnyObject]! {
        get { return Cache.workTargets }
        set {
            Cache.workTargets = newValue
            for target: AnyObject in newValue {
                target.performSelector(NSSelectorFromString("setImage:"), withObject: LabelStyleKit.imageOfWork)
            }
        }
    }

    @IBOutlet dynamic var otherTargets: [AnyObject]! {
        get { return Cache.otherTargets }
        set {
            Cache.otherTargets = newValue
            for target: AnyObject in newValue {
                target.performSelector(NSSelectorFromString("setImage:"), withObject: LabelStyleKit.imageOfOther)
            }
        }
    }




    @objc public enum ResizingBehavior: Int {
        case AspectFit /// The content is proportionally resized to fit into the target rectangle.
        case AspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case Stretch /// The content is stretched to match the entire target rectangle.
        case Center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
                case .AspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .AspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .Stretch:
                    break
                case .Center:
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
