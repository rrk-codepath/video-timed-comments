//
//  AppDelegate.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/8/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit
import Parse
import Google
import GoogleSignIn
import FTIndicator
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        // Override point for customization after application launch.
        Parse.setApplicationId("6OvJ4QaZiK9QN8jZpjVHoEO8IZ9kqks9ThGny7c8",
                               clientKey: "x4S9CP9dhOj6pXCRNb4yWzWHIiPF195MXc03TbIb")
        //Hack to solve issues with spinner
        FTIndicator.showProgressWithmessage("")
        FTIndicator.dismissProgress()
        
        // Initialize sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let currentUser = PFUser.current() {
            self.logUser()
            Answers.logCustomEvent(withName: "Launched app", customAttributes: ["userId" : currentUser.objectId!])
            GIDSignIn.sharedInstance().signInSilently()
            let vc = storyboard.instantiateViewController(withIdentifier: "HomeNavigationViewController") as! UINavigationController
            // TODO: animation does not work
            UIView.transition(with: self.window!, duration: 0.5, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: {
                self.window?.rootViewController = vc
            }, completion: nil)
            
        }
        
        return true
    }
    
    func logUser() {
        // TODO: Use the current user's information
        // You can call any combination of these three methods
        Crashlytics.sharedInstance().setUserEmail(PFUser.current()?.email)
        Crashlytics.sharedInstance().setUserIdentifier(PFUser.current()?.objectId)
        Crashlytics.sharedInstance().setUserName(PFUser.current()?.username)
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if PFUser.current() != nil {
            GIDSignIn.sharedInstance().signInSilently()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Example url: notate://notate/mY237ab1
        if url.host == "notate" {
            var notateId = url.path
            notateId.remove(at: url.path.startIndex)
            // Navigate to the detail VC with this joomped ID
            let rootViewController = self.window?.rootViewController as! UINavigationController
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let joompedViewController = mainStoryboard.instantiateViewController(withIdentifier: "joomped") as! JoompedViewController
            joompedViewController.joompedId = notateId
            rootViewController.pushViewController(joompedViewController, animated: true)
            return true
        }
        
        return GIDSignIn.sharedInstance().handle(url,
            sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplicationOpenURLOptionsKey.annotation])
    }
}
