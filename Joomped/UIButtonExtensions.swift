//
//  UIButtonExtensions.swift
//  Joomped
//
//  Created by Keith Lee on 12/3/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsetsMake(-8, -8, -8, -8)
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
