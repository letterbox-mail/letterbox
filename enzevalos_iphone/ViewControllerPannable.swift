//
//  ViewControllerPannable.swift
//  enzevalos_iphone
//
//  Created by Joscha on 03.08.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//
//  https://stackoverflow.com/a/41077052

class ViewControllerPannable: UIViewController {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
    }

    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)

        if panGesture.state == .began {
            originalPosition = view.center
            currentPositionTouched = panGesture.location(in: view)
            
        } else if panGesture.state == .changed {
            view.frame.origin = CGPoint(
                x: 0,
                y: translation.y
            )
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)

            if velocity.y >= 1500 || translation.y >= 300 {
                UIView.animate(withDuration: 0.2
                               , animations: {
                                   self.view.frame.origin = CGPoint(
                                                                        x: self.view.frame.origin.x,
                                                                        y: self.view.frame.size.height
                                   )
                               }, completion: { (isCompleted) in
                                   if isCompleted {
                                       self.dismiss(animated: false, completion: nil)
                                   }
                               })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition!
                })
            }
        }
    }
}
