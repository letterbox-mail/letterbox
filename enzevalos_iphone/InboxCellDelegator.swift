//
//  InboxCellDelegator.swift
//  readView
//
//  Created by Joscha on 09.09.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

protocol InboxCellDelegator: class {

    func callSegueFromCell(_ mail: PersistentMail?)
    func callSegueFromCell2(_ contact: KeyRecord?)
    func callSegueToContact(_ contact: KeyRecord?)
}
