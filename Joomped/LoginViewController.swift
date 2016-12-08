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
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var signupButton: UIButton!
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        titleLabel.setTextWithTypeAnimation(typedText: "Notate", characterInterval: 0.3)
    }
    
    override func viewDidLayoutSubviews() {
        //Fixes issues with frame changin when tapping on tapping and switching textfields
        if keyboardShown {
            self.scrollView.frame.origin.y = newFrame
        }
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
    
    @IBAction func onTapGidSignIn(_ sender: Any) {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()

        googleSignInButton.isHidden = true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if self.scrollView.frame.origin.y > 0 {
            let info  = notification.userInfo!
            let value: NSValue = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
            
            let rawFrame = value.cgRectValue
            let keyboardFrame = view.convert(rawFrame, from: nil)
            if keyboardFrame.size.height == 0 {
                return
            }
            
            let screenHeight = UIScreen.main.bounds.size.height;
            let Ylimit = screenHeight - keyboardFrame.size.height
            let textboxOriginInSuperview:CGPoint = self.view.convert(CGPoint.zero, from: self.signupButton)
            
            let keyboardHeight = (textboxOriginInSuperview.y+self.signupButton!.frame.size.height) - Ylimit
            self.scrollView.frame.origin.y -= keyboardHeight + 12
            newFrame = self.scrollView.frame.origin.y
            keyboardShown = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        keyboardShown = false
        self.scrollView.frame.origin.y = originalFrame
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
        
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        
        googleSignInButton.isHidden = false
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
        loadingIndicator.isHidden = true

    }
    
    func login(didFailWith error: Error?) {
        print("\(error?.localizedDescription)")
        onLoginFailure()
        loadingIndicator.isHidden = true
    }
}
