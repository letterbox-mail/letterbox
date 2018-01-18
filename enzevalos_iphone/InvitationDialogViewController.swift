//
//  InvitationDialogViewController.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

class InvitationDialogViewController					: UIViewController {

	// MARK: - IBOutlet

	@IBOutlet fileprivate weak var dialogView			: UIView?

	@IBOutlet fileprivate weak var iconImageView		: UIImageView?
	@IBOutlet fileprivate weak var iconBackgroundView	: UIView?
	@IBOutlet fileprivate weak var titleLabel			: UILabel?
	@IBOutlet fileprivate weak var messageLabel			: UILabel?

	@IBOutlet fileprivate weak var ctaButton			: UIButton?
	@IBOutlet fileprivate weak var dismissButton		: UIButton?

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

extension InvitationDialogViewController {

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
		self.titleLabel?.textColor = UIColor.Invitation.gray
		self.messageLabel?.textColor = UIColor.Invitation.gray
	}
}

// MARK: - Presentation

extension InvitationDialogViewController {

	static func present(on viewController: UIViewController, animated: Bool) {

		guard let invitationViewController = UIStoryboard(name: "InvitationDialog", bundle: nil).instantiateInitialViewController() else {
			return
		}

		invitationViewController.view.isOpaque = false
		invitationViewController.modalPresentationStyle = .overCurrentContext

		viewController.present(invitationViewController, animated: false, completion: nil)
	}
}

// MARK: - Animation

extension InvitationDialogViewController {

	func showDialog(_ animated: Bool) {
		let animationInterval: TimeInterval = ((animated == true) ? 0.3 : 0)
		self.dialogView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
		self.dialogView?.alpha = 0
		self.dialogView?.isHidden = false

		UIView.animate(withDuration: animationInterval, animations: { [weak self] in
			self?.dialogView?.transform = CGAffineTransform.identity
			self?.dialogView?.alpha = 1
		})
	}
}

// MARK: - IBAction

extension InvitationDialogViewController {

	@IBAction private func ctaButtonTapped(sender: Any) {

	}

	@IBAction private func dismissButtonTapped(sender: Any) {

	}
}
