//
//  ReplaceStoryboardSegue.swift
//  Joomped
//
//  Created by R-J Lim on 11/22/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit

class ReplaceStoryboardSegue: UIStoryboardSegue {
    
    override func perform() {
        let navigationController = source.navigationController
        if let navigationController = navigationController,
            let delegate = UIApplication.shared.delegate,
            let window = delegate.window {
            navigationController.dismiss(animated: false, completion: nil)
            UIView.transition(with: window!, duration: 0.3, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                window!.rootViewController = self.destination
            }, completion: nil)
        }
    }

}
