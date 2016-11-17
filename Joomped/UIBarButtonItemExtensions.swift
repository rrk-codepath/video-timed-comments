//
//  UIBarButtonItemExtensions.swift
//  Joomped
//
//  Created by Keith Lee on 11/16/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem {
    func rrk_hidden() {
        self.tintColor = UIColor.clear
        self.isEnabled = false
    }
}
