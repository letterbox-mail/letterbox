//
//  RefreshControlExtension.swift
//  enzevalos_iphone
//
//  Created by Joscha on 05.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit
import Foundation

extension UIRefreshControl {
    func beginRefreshingManually() {
        if let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height), animated: true)
        }
        beginRefreshing()
        sendActionsForControlEvents(UIControlEvents.ValueChanged)
    }
}
