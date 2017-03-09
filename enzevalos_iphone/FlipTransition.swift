//
//  FlipTransition.swift
//  enzevalos_iphone
//
//  from: https://stackoverflow.com/questions/37980243/how-to-create-a-custom-flip-horizontally-push-segue-like-the-one-thats-used-f
//

import Foundation
import UIKit

class FlipTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let container = transitionContext.containerView()
        container.addSubview(toVC.view)
        container.bringSubviewToFront(fromVC!.view)

        var transfrom = CATransform3DIdentity
        transfrom.m34 = -0.002
        container.layer.sublayerTransform = transfrom

        let initalFrame = transitionContext.initialFrameForViewController(fromVC!)
        toVC.view.frame = initalFrame
        fromVC!.view.frame = initalFrame
        toVC.view.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI_2), 0, 1, 0)

        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            fromVC!.view.layer.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 1, 0)
        }) { (finished: Bool) -> Void in
            container.bringSubviewToFront(toVC.view)
            UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                toVC.view.layer.transform = CATransform3DIdentity
            }) { (finished: Bool) -> Void in

                fromVC!.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }

        }
    }
}
