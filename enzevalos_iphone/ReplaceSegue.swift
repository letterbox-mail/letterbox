//
//  ReplaceSegue.swift
//  enzevalos_iphone
//
//  From: https://stackoverflow.com/questions/21414786/instead-of-push-segue-how-to-replace-view-controller-or-remove-from-navigation
//

import Foundation
import UIKit

class ReplaceSegue: UIStoryboardSegue {
    override func perform() {

        if let navigationController = source.navigationController {

            var controllerStack = navigationController.viewControllers
            let index = controllerStack.index(of: source)
            controllerStack[index!] = destination

            navigationController.setViewControllers(controllerStack, animated: true)
        }
    }
}
