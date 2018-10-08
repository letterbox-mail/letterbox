//
//  DialogViewController.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class DialogViewController									: UIViewController {

	// MARK: - IBOutlet

	@IBOutlet fileprivate weak var dialogView				: UIView?
	@IBOutlet fileprivate weak var titleView				: UIView?

	@IBOutlet fileprivate weak var iconImageView			: UIImageView?
	@IBOutlet fileprivate weak var iconBackgroundView		: UIView?
	@IBOutlet fileprivate weak var iconBackgroundImageView	: UIImageView?
	@IBOutlet fileprivate weak var titleLabel				: UILabel?
	@IBOutlet fileprivate weak var messageLabel				: UILabel?

	@IBOutlet fileprivate weak var ctaButton				: UIButton?
	@IBOutlet fileprivate weak var additionalButton			: UIButton?
	@IBOutlet fileprivate weak var dismissButton			: UIButton?

	@IBOutlet fileprivate var heightConstraint				: NSLayoutConstraint?
	@IBOutlet fileprivate var spacingConstraint				: NSLayoutConstraint?

	// MARK: - Action

	var ctaAction											: (() -> Void)?
	var additionalAction									: (() -> Void)?
	var dismissAction										: (() -> Void)?

	// MARK: - Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.layoutSubviews()
		self.dialogView?.isHidden = true
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.showDialog(animated)
	}
}

// MARK: - Layout

extension DialogViewController {

	fileprivate func layoutSubviews() {

		self.dialogView?.roundRect(15)
		self.dialogView?.layer.borderWidth = 0.5
		self.dialogView?.layer.borderColor = UIColor.Invitation.gray.cgColor
		self.iconImageView?.image = UIImage(named: "ic_secure_card")?.withRenderingMode(.alwaysTemplate)
		self.iconImageView?.tintColor = UIColor.Invitation.gray
		self.iconBackgroundView?.roundRect()
		self.iconBackgroundView?.layer.borderWidth = 1
		self.iconBackgroundView?.layer.borderColor = UIColor.Invitation.gray.cgColor
		self.ctaButton?.backgroundColor = UIColor.Invitation.orange
		self.ctaButton?.setTitleColor(.white, for: .normal)
		self.ctaButton?.roundRect(5)
		self.dismissButton?.setTitleColor(UIColor.Invitation.gray, for: .normal)
		self.additionalButton?.setTitleColor(UIColor.Invitation.gray, for: .normal)
		self.titleLabel?.textColor = UIColor.Invitation.gray
		self.messageLabel?.textColor = UIColor.Invitation.gray
	}

	func layout(for option: DialogOption) {
		self.titleLabel?.isHidden = (option.title == nil)
		self.titleLabel?.text = option.title
		self.messageLabel?.isHidden = (option.message == nil)
		self.messageLabel?.text = option.message
		self.ctaButton?.isHidden = (option.ctaButtonTitle == nil)
		self.ctaButton?.setTitle(option.ctaButtonTitle, for: .normal)
		self.dismissButton?.isHidden = (option.dismissButtonTitle == nil)
		self.dismissButton?.setTitle(option.dismissButtonTitle, for: .normal)
		self.additionalButton?.isHidden = (option.additionActionButtonTitle == nil)
		self.additionalButton?.setTitle(option.additionActionButtonTitle, for: .normal)
		self.titleView?.backgroundColor = option.color
		self.iconImageView?.image = option.icon?.withRenderingMode(.alwaysTemplate)
		self.iconBackgroundView?.isHidden = option.icon == nil
		self.iconBackgroundImageView?.image = option.titleImage
        if let animated = self.iconBackgroundImageView?.isAnimating, animated == true {
            self.iconBackgroundImageView?.animationRepeatCount = -1
        }
		self.ctaButton?.backgroundColor = option.color

		self.heightConstraint?.constant = ((option.titleImage != nil) ? 150 : 100)
		self.spacingConstraint?.constant = ((option.icon == nil) ? 16 : -49)
		self.dialogView?.layoutIfNeeded()
	}
}

// MARK: - Presentation

extension DialogViewController {

	static func present(on viewController: UIViewController, with option: DialogOption, completion: (() -> Void)? = nil) -> DialogViewController? {

		guard let dialogViewController = UIStoryboard(name: "Dialog", bundle: nil).instantiateInitialViewController() as? DialogViewController else {
			return nil
		}

		dialogViewController.view.isOpaque = false
		dialogViewController.modalPresentationStyle = .overCurrentContext
		dialogViewController.layout(for: option)

		viewController.present(dialogViewController, animated: false, completion: completion)

		return dialogViewController
	}

	func markDismissButton(with option: DialogOption) {

		self.ctaButton?.backgroundColor = .clear
		self.ctaButton?.setTitleColor(UIColor.Invitation.gray, for: .normal)
		self.dismissButton?.backgroundColor = option.color
		self.dismissButton?.setTitleColor(.white, for: .normal)
		self.dismissButton?.roundRect(5)
	}
}

// MARK: - Animation

extension DialogViewController {

	fileprivate func showDialog(_ animated: Bool) {

		let animationInterval: TimeInterval = ((animated == true) ? 0.3 : 0)
		self.dialogView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
		self.dialogView?.alpha = 0
		self.dialogView?.isHidden = false

		UIView.animate(withDuration: animationInterval, animations: { [weak self] in
			self?.dialogView?.transform = CGAffineTransform.identity
			self?.dialogView?.alpha = 1
		})
	}

	fileprivate func hideDialog(_ animated: Bool, completion: (() -> Void)?) {

		let animationInterval: TimeInterval = ((animated == true) ? 0.3 : 0)

		UIView.animate(withDuration: animationInterval, animations: { [weak self] in
			self?.dialogView?.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
			self?.dialogView?.alpha = 0
		}) { (completed: Bool) in
			completion?()
		}
	}

	public func hideDialog(completion: (() -> Void)?) {
		self.hideDialog(true) { [weak self] in
			self?.dismiss(animated: false, completion: {
				completion?()
			})
		}
	}
}

// MARK: - IBAction

extension DialogViewController {

	@IBAction private func ctaButtonTapped(sender: Any) {

        self.hideDialog(true) { [weak self] in
            self?.dismiss(animated: false, completion: { [weak self] in
                self?.ctaAction?()
            })
        }
	}

	@IBAction private func additionalButtonTapped(sender: Any) {

		self.hideDialog(true) { [weak self] in
			self?.dismiss(animated: false, completion: { [weak self] in
				self?.additionalAction?()
			})
		}
	}

	@IBAction private func dismissButtonTapped(sender: Any) {

		self.hideDialog(true) { [weak self] in
			self?.dismiss(animated: false, completion: { [weak self] in
				self?.dismissAction?()
			})
		}
	}
}
