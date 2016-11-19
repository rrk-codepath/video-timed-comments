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
    @IBOutlet weak var searchBar: UISearchBar!
    
    var selectedJoomped: Joomped?
    var selectedYoutubeVideo: YoutubeVideo?
    
    fileprivate var joomped: [Joomped] = []
    fileprivate var youtubeVideos: [YoutubeVideo] = []
    fileprivate var searchMode = SearchMode.joomped
    
    private let youtube = Youtube()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Following code won't work until we re-add joomped table view to storyboard
        
        joompedTableView.register(UINib(nibName: "JoompedTableViewCell", bundle: nil), forCellReuseIdentifier: "Joomped")
        joompedTableView.register(UINib(nibName: "YoutubeVideoTableViewCell", bundle: nil), forCellReuseIdentifier: "YoutubeVideo")
        
        joompedTableView.dataSource = self
        joompedTableView.delegate = self
        joompedTableView.rowHeight = UITableViewAutomaticDimension
        joompedTableView.estimatedRowHeight = 50
        
        searchBar.delegate = self
        
        fetchJoomped(refreshControl: nil)
        
        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchJoomped(refreshControl:)), for: UIControlEvents.valueChanged)
        joompedTableView.insertSubview(refreshControl, at: 0)
    }
    
    @IBAction func onSearchModeChanged(_ sender: UISegmentedControl) {
        searchMode = SearchMode(rawValue: sender.selectedSegmentIndex)!
        search()
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
    
    fileprivate func search() {
        guard let term = searchBar.text else {
            return
        }
        
        joompedTableView.reloadData()
        
        switch searchMode {
        case SearchMode.joomped:
            searchJoomped(term: term)
            break
        case SearchMode.youtube:
            searchYoutube(term: term)
            break
        }
    }
    
    private func searchJoomped(term: String) {
        let query = PFQuery(className:"Joomped")
        
        if !term.isEmpty {
            let videoQuery = PFQuery(className: "Video")
            videoQuery.whereKey("title", contains: term)
            query.whereKey("video", matchesQuery: videoQuery)
        }

        // Retrieve the most recent ones
        query.order(byDescending: "createdAt")
        // Should limit once we're making millions of dollars
        // query.limit = 10
        
        query.includeKeys(["video", "user", "annotations.Annotation"])
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            self.joomped = objects as? [Joomped] ?? []
            self.joompedTableView.reloadData()
        }
    }
    
    private func searchYoutube(term: String) {
        if term.isEmpty {
            if youtube.authenticated {
                youtube.liked(success: { (videos: [YoutubeVideo]) in
                    self.youtubeVideos = videos
                    self.joompedTableView.reloadData()
                }, failure: { (error: Error) in
                    print("error: \(error.localizedDescription)")
                })
            } else {
                youtube.popular(success: { (videos: [YoutubeVideo]) in
                    self.youtubeVideos = videos
                    self.joompedTableView.reloadData()
                }, failure: { (error: Error) in
                    print("error: \(error.localizedDescription)")
                })
            }
        } else {
            youtube.search(
                term: term,
                success: { (videos: [YoutubeVideo]) -> Void in
                    self.youtubeVideos = videos
                    self.joompedTableView.reloadData()
                },
                failure: { (error: Error) -> Void in
                    print("error: \(error.localizedDescription)")
                }
            )
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
        switch segue.identifier! {
        case "ConsumptionSegue":
            let jvc = segue.destination as! JoompedViewController
            jvc.joomped = selectedJoomped
            break
        case "CreationSegue":
            let jvc = segue.destination as! JoompedViewController
            jvc.youtubeVideo = selectedYoutubeVideo
            jvc.isEditMode = true
            break
        default:
            return
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch searchMode {
        case SearchMode.joomped:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Joomped") as! JoompedTableViewCell
            cell.joomped = joomped[indexPath.row]
            return cell
        case SearchMode.youtube:
            let cell = tableView.dequeueReusableCell(withIdentifier: "YoutubeVideo") as! YoutubeVideoTableViewCell
            cell.youtubeVideo = youtubeVideos[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchMode {
        case SearchMode.joomped:
            return joomped.count
        case SearchMode.youtube:
            return youtubeVideos.count
        }
    }
}

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch searchMode {
        case SearchMode.joomped:
            selectedJoomped = joomped[indexPath.row]
            performSegue(withIdentifier: "ConsumptionSegue", sender: self)
            break
        case SearchMode.youtube:
            selectedYoutubeVideo = youtubeVideos[indexPath.row]
            performSegue(withIdentifier: "CreationSegue", sender: self)
            break
        }
    }
}

extension HomeViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        search()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
        searchBar.resignFirstResponder()
    }
}

fileprivate enum SearchMode: Int {
    case joomped = 0
    case youtube
}
