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

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    
    private let signInDelegate = ParseGoogleSignInDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInDelegate.delegate = self
        
        GIDSignIn.sharedInstance().delegate = signInDelegate
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    @IBAction func didTapLogin(_ sender: Any) {
        PFUser.logInWithUsername(inBackground: usernameTextField.text!, password: passwordTextField.text!) { (user: PFUser?, error: Error?) in
                if let user = user {
                    print("logged in as: \(user.username!)")
                    self.performSegue(withIdentifier: "HomeSegue", sender: self)
                } else {
                    self.onLoginFailure()
                }
            }
    }
    
    fileprivate func onLoginFailure() {
        let alertController = UIAlertController(title: "Failure", message: "Failed to login", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // dismiss by default
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: {
            // empty
        })
    }

    @IBAction func didTapSignup(_ sender: Any) {
        let user = User()
        user.username = usernameTextField.text
        user.displayName = usernameTextField.text
        user.password = passwordTextField.text
        //        user.email = "email@example.com"
        
        user.signUpInBackground {
            (succeeded: Bool, error: Error?) -> Void in
            if let error = error {
                print("error: \(error.localizedDescription)")
                // let errorString = error.userInfo["error"] as? String
                // Show the errorString somewhere and let the user try again.
                let alertController = UIAlertController(title: "Failure", message: "Failed to signup", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    // dismiss by default
                }
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: {
                    // empty
                })
            } else {
                self.performSegue(withIdentifier: "HomeSegue", sender: self)
                // Hooray! Let them use the app now.
                print("signed up")
            }
        }
    }
}

extension LoginViewController: GIDSignInUIDelegate {
}


extension LoginViewController: ParseLoginDelegate {
    
    func login(didSucceedFor user: PFUser) {
        performSegue(withIdentifier: "HomeSegue", sender: self)
    }
    
    func login(didFailWith error: Error?) {
        print("\(error?.localizedDescription)")
        onLoginFailure()
    }
}

