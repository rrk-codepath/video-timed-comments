//
//  HomeViewController.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/9/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit
import GoogleSignIn
import Parse

class HomeViewController: UIViewController {

    @IBOutlet weak var joompedTableView: UITableView!
    fileprivate var joomped: [Joomped] = []
    var selectedJoompedCell: JoompedTableViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Following code won't work until we re-add joomped table view to storyboard
        
        joompedTableView.register(UINib(nibName: "JoompedTableViewCell", bundle: nil), forCellReuseIdentifier: "Joomped")
        joompedTableView.dataSource = self
        joompedTableView.delegate = self
        joompedTableView.rowHeight = UITableViewAutomaticDimension
        joompedTableView.estimatedRowHeight = 50
        fetchJoomped(refreshControl: nil)
        
        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchJoomped(refreshControl:)), for: UIControlEvents.valueChanged)
        joompedTableView.insertSubview(refreshControl, at: 0)
    }
    
    @objc private func fetchJoomped(refreshControl: UIRefreshControl?) {
        let query = PFQuery(className:"Joomped")
        query.includeKey("annotations.Annotation")
        
        // Retrieve the most recent ones
        query.order(byDescending: "createdAt")
        
        // Should limit once we're making millions of dollars
        // query.limit = 10
        
        query.includeKeys(["video", "user"])
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            self.joomped = objects as? [Joomped] ?? []
            self.joompedTableView.reloadData()
            if let refreshControl = refreshControl {
                refreshControl.endRefreshing()
            }
        }
    }

    @IBAction func onLogout(_ sender: Any) {
        PFUser.logOutInBackground { (error: Error?) in
            GIDSignIn.sharedInstance().signOut()
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            appdelegate.window!.rootViewController = mainStoryboard.instantiateInitialViewController()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ConsumptionSegue" {
            let jvc = segue.destination as! JoompedViewController
            jvc.joomped = selectedJoompedCell?.joomped
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return joomped.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Joomped") as! JoompedTableViewCell
        cell.joomped = joomped[indexPath.row]
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        joompedTableView.deselectRow(at: indexPath, animated: true)
        selectedJoompedCell = tableView.cellForRow(at: indexPath) as? JoompedTableViewCell
        performSegue(withIdentifier: "ConsumptionSegue", sender: self)
    }
}
