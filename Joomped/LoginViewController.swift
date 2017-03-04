//
//  LoginViewController.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/8/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit
import Parse
import GoogleSignIn

class LoginViewController: UIViewController {

    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var originalFrame: CGFloat!
    private var newFrame: CGFloat!
    private let signInDelegate = ParseGoogleSignInDelegate()
    private var keyboardShown: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInDelegate.delegate = self
        GIDSignIn.sharedInstance().delegate = signInDelegate
        GIDSignIn.sharedInstance().uiDelegate = self
        
        originalFrame = self.scrollView.frame.origin.y
        
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        
        titleLabel.setTextWithTypeAnimation(typedText: "Notate", characterInterval: 0.3)
    }
    
    override func viewDidLayoutSubviews() {
        //Fixes issues with frame changin when tapping on tapping and switching textfields
        if keyboardShown {
            self.scrollView.frame.origin.y = newFrame
        }
    }
    
    @IBAction func onTapGidSignIn(_ sender: Any) {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()

        googleSignInButton.isHidden = true
    }
    
    fileprivate func onLoginFailure(error: Error?) {
        let alertController = UIAlertController(title: "Failed to login", message: error?.localizedDescription, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // dismiss by default
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: {
            // empty
        })
        
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        
        googleSignInButton.isHidden = false
    }
}

extension LoginViewController: GIDSignInUIDelegate {}

extension LoginViewController: ParseLoginDelegate {
    
    func login(didSucceedFor user: PFUser) {
        performSegue(withIdentifier: "HomeSegue", sender: self)
        loadingIndicator.isHidden = true
    }
    
    func login(didFailWith error: Error?) {
        onLoginFailure(error: error)
        loadingIndicator.isHidden = true
    }
}
