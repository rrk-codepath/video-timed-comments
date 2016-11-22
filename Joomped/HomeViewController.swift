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
    @IBOutlet weak var searchModeSegmentedControl: UISegmentedControl!
    @IBOutlet var viewTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tableViewActivityIndicator: UIActivityIndicatorView!
    
    var selectedJoomped: Joomped?
    var selectedYoutubeVideo: YoutubeVideo?
    
    fileprivate var joomped: [Joomped] = []
    fileprivate var youtubeVideos: [YoutubeVideo] = []
    fileprivate var searchMode = SearchMode.joomped
    
    private let youtube = Youtube()
    private var youtubeSearchText: String?
    private var joompedSearchText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Following code won't work until we re-add joomped table view to storyboard
        
        joompedTableView.register(UINib(nibName: "JoompedTableViewCell", bundle: nil), forCellReuseIdentifier: "Joomped")
        joompedTableView.register(UINib(nibName: "YoutubeVideoTableViewCell", bundle: nil), forCellReuseIdentifier: "YoutubeVideo")
        
        joompedTableView.dataSource = self
        joompedTableView.delegate = self
        joompedTableView.rowHeight = UITableViewAutomaticDimension
        joompedTableView.estimatedRowHeight = 50
        joompedTableView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0)
        joompedTableView.isHidden = true
        tableViewActivityIndicator.startAnimating()
        
        navigationItem.titleView = searchBar
        
        searchBar.delegate = self
        
        searchModeSegmentedControl.layer.cornerRadius = 4.0
        searchModeSegmentedControl.clipsToBounds = true
        
        fetchJoomped(refreshControl: nil)
        
        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchJoomped(refreshControl:)), for: UIControlEvents.valueChanged)
        joompedTableView.insertSubview(refreshControl, at: 0)
    }
    
    @IBAction func onSearchModeChanged(_ sender: UISegmentedControl) {
        searchMode = SearchMode(rawValue: sender.selectedSegmentIndex)!
        searchBar.placeholder = searchMode.text
        switch searchMode {
        case .joomped:
            searchBar.text = joompedSearchText
            break
        case .youtube:
            searchBar.text = youtubeSearchText
            break
        }
        
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
            self.reloadTable()
            if let refreshControl = refreshControl {
                refreshControl.endRefreshing()
            }
        }
    }
    
    private func reloadTable() {
        self.joompedTableView.isHidden = false
        self.tableViewActivityIndicator.stopAnimating()
        self.joompedTableView.reloadData()
    }
    
    fileprivate func search() {
        guard let term = searchBar.text else {
            return
        }
        
        joompedTableView.reloadData()
        if joompedTableView.visibleCells.count == 0 {
            joompedTableView.isHidden = true
            tableViewActivityIndicator.startAnimating()
        }
        
        switch searchMode {
        case SearchMode.joomped:
            if joompedSearchText != term {
                searchJoomped(term: term)
                joompedSearchText = searchBar.text
            }
            break
        case SearchMode.youtube:
            if youtubeSearchText != term {
                searchYoutube(term: term)
                youtubeSearchText = searchBar.text
            }
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
            self.reloadTable()
        }
    }
    
    private func searchYoutube(term: String) {
        if term.isEmpty {
            if youtube.authenticated {
                youtube.liked(success: { (videos: [YoutubeVideo]) in
                    self.youtubeVideos = videos
                    self.reloadTable()
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
    
    @IBAction func onViewTapped(_ sender: UITapGestureRecognizer) {
        searchBar.resignFirstResponder()
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
    
    fileprivate func hideSearchMode() {
        fadeSearchMode(toOpacity: 0.0)
    }
    
    fileprivate func showSearchMode() {
        if joompedTableView.contentOffset.y < 30 {
            fadeSearchMode(toOpacity: 1.0)
        }
    }
    
    private func fadeSearchMode(toOpacity opacity: CGFloat) {
        if self.searchModeSegmentedControl.alpha != opacity {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.searchModeSegmentedControl.alpha = opacity
            })
        }
    }
}

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        hideSearchMode()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        showSearchMode();
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        showSearchMode()
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
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewTapGestureRecognizer.isEnabled = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewTapGestureRecognizer.isEnabled = false
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
    
    var text: String {
        switch self {
        case .joomped:
            return "Find annotations"
        case .youtube:
            return "Find something to annotate"
        }
    }
}
