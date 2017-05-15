//
//  FlipTransition.swift
//  enzevalos_iphone
//
//  adapted from: https://stackoverflow.com/questions/37980243/how-to-create-a-custom-flip-horizontally-push-segue-like-the-one-thats-used-f
//

import Foundation
import UIKit

class FlipTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let container = transitionContext.containerView
        container.backgroundColor = UIColor.darkGray
        container.addSubview(toVC.view)
        container.bringSubview(toFront: fromVC!.view)

        var transfrom = CATransform3DIdentity
        transfrom.m34 = -0.001
        container.layer.sublayerTransform = transfrom

        let initalFrame = transitionContext.initialFrame(for: fromVC!)
        toVC.view.frame = initalFrame
        fromVC!.view.frame = initalFrame
        toVC.view.layer.transform = CATransform3DMakeRotation(.pi / 2, 0, 1, 0)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: { () -> Void in
            fromVC!.view.layer.transform = CATransform3DMakeRotation(.pi / -2, 0, 1, 0)
        }) { (finished: Bool) -> Void in
            container.bringSubview(toFront: toVC.view)
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: { () -> Void in
                toVC.view.layer.transform = CATransform3DIdentity
            }) { (finished: Bool) -> Void in

                fromVC!.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
