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

        if let navigationController = sourceViewController.navigationController {

            var controllerStack = navigationController.viewControllers
            let index = controllerStack.indexOf(sourceViewController)
            controllerStack[index!] = destinationViewController

            navigationController.setViewControllers(controllerStack, animated: true)
        }
    }
}
