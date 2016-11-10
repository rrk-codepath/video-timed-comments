//
//  LoginViewController.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/8/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit
import Parse

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didTapLogin(_ sender: Any) {
        let user = try? PFUser.logIn(withUsername: usernameTextField.text!, password: passwordTextField.text!)
        if let user = user {
            print("logged in as: \(user.username)")
            self.performSegue(withIdentifier: "HomeSegue", sender: self)
        } else {
            print("could not login: \(user)")
            let alertController = UIAlertController(title: "Failure", message: "Failed to login", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                // dismiss by default
            }
            alertController.addAction(OKAction)
            present(alertController, animated: true, completion: {
                // empty
            })
        }
    }

    @IBAction func didTapSignup(_ sender: Any) {
        let user = PFUser()
        user.username = usernameTextField.text
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
        
        let jooomped = Joomped()
        print("created at=\(jooomped.createdAt)")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
