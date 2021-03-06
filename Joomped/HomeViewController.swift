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
import iOSSharedViewTransition
import FTIndicator
import Fabric
import Crashlytics

class HomeViewController: UIViewController {
    
    private static let presetTerms = [
        "The School of Life",
        "TED Talk",
        "Wisecrack",
        "Philosophy Tube",
        "Draw With Jazza",
        "BBC Earth",
        "Gresham College",
        "Healthcare Triage",
        "THNKR",
        "Codepath",
        "GoogleTalks",
        "Bad Astronomy",
        "Big Think",
        "British Film Institute National Archive",
        "American Museum of Natural History",
        "Artists Space",
        "Al Jazeera English",
        "Aspen Institute",
        "Brooklyn Museum",
        "Canal Educatif",
        "Computer History Museum",
        "Reuters Video",
        "The New York Times",
        "YouTube EDU",
        "University of California – Berkeley",
        "Stanford University"
    ]
    
    @IBOutlet weak var profileBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var joompedTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControlBackground: UIView!
    @IBOutlet weak var searchModeSegmentedControl: UISegmentedControl!
    @IBOutlet var viewTapGestureRecognizer: UITapGestureRecognizer!
    //Now used for white status bar on scroll
    @IBOutlet weak var tableViewActivityIndicator: UIActivityIndicatorView!
    
    var selectedJoomped: Joomped?
    var selectedYoutubeVideo: YoutubeVideo?
    
    fileprivate var joomped: [Joomped] = []
    fileprivate var youtubeVideos: [YoutubeVideo] = []
    fileprivate var searchMode = SearchMode.joomped
    fileprivate var lastContentOffset: CGFloat?
    fileprivate var selectedThumbnail: UIImageView?
    
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
        joompedTableView.estimatedRowHeight = 114
        joompedTableView.rowHeight = 114
        joompedTableView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0)
        joompedTableView.isHidden = true
        ASFSharedViewTransition.addWith(fromViewControllerClass: HomeViewController.self, toViewControllerClass: JoompedViewController.self, with: self.navigationController, withDuration: 0.3)
        
        navigationItem.titleView = searchBar
        
        searchBar.delegate = self
        
        searchModeSegmentedControl.layer.cornerRadius = 4.0
        searchModeSegmentedControl.clipsToBounds = true
        
        fetchJoomped(refreshControl: nil)
        
        // Pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchJoomped(refreshControl:)), for: UIControlEvents.valueChanged)
        joompedTableView.insertSubview(refreshControl, at: 0)
        
        if let user = PFUser.current() as? User,
            let imageUrl = user.imageUrl,
            let url = URL(string: imageUrl) {
        let profileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            profileImageView.setImageWith(url)
            profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
            profileImageView.clipsToBounds = true
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(onTappedProfile(_:)))
            profileImageView.addGestureRecognizer(gesture)
            profileBarButtonItem.customView = profileImageView
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        joompedTableView.reloadData()
    }
    
    @IBAction func onSearchModeChanged(_ sender: UISegmentedControl) {
        searchMode = SearchMode(rawValue: sender.selectedSegmentIndex)!
        Answers.logCustomEvent(withName: "Change search mode",
                               customAttributes: ["searchMode" : searchMode == .joomped ? "joomped" : "youtube"])
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
        query.includeKey("annotations")
        
        // Retrieve the most recent ones
        query.order(byDescending: "createdAt")
        
        // Should limit once we're making millions of dollars
        // query.limit = 10
        
        query.includeKeys(["video", "user"])
        
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            DispatchQueue.main.async(execute: {
                self.joomped = objects as? [Joomped] ?? []
                self.reloadTable()
                if let refreshControl = refreshControl {
                    refreshControl.endRefreshing()
                }
            })
        }
    }
    
    private func reloadTable() {
        self.joompedTableView.isHidden = false
        self.joompedTableView.reloadData()
        FTIndicator.dismissProgress()
    }
    
    fileprivate func search() {
        search(forceRefresh: false)
    }
    
    fileprivate func search(forceRefresh: Bool) {
        guard let term = searchBar.text else {
            return
        }
        
        joompedTableView.reloadData()
        
        switch searchMode {
        case SearchMode.joomped:
            if forceRefresh || joompedSearchText != term {
                FTIndicator.showProgressWithmessage("")
                searchJoomped(term: term)
                joompedSearchText = searchBar.text
            }
            break
        case SearchMode.youtube:
            if forceRefresh || youtubeSearchText != term {
                FTIndicator.showProgressWithmessage("")
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
            videoQuery.whereKey("lowercaseTitle", contains: term.lowercased())
            query.whereKey("video", matchesQuery: videoQuery)
        }

        // Retrieve the most recent ones
        query.order(byDescending: "createdAt")
        // Should limit once we're making millions of dollars
        // query.limit = 10
        
        query.includeKeys(["video", "user", "annotations"])
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            DispatchQueue.main.async(execute: { 
                self.joomped = objects as? [Joomped] ?? []
                self.reloadTable()
            })
        }
    }
    
    private func searchYoutube(term: String) {
        if term.isEmpty {
            performYoutubeSearch(term: randomPresetTerm())
        } else {
            if let youtubeId = extractYoutubeIdFromLink(link: term) {
                Answers.logCustomEvent(withName: "Paste youtube link", customAttributes: ["youtubeId": youtubeId])
                youtube.videoIds(
                    videoIds: [youtubeId],
                    success: { (videos: [YoutubeVideo]) in
                        self.selectedYoutubeVideo = videos[0]
                        self.performSegue(withIdentifier: "CreationSegue", sender: self)
                    },
                    failure: { (error: Error) -> Void in
                        print("error: \(error.localizedDescription)")
                        // Fallback to search
                        self.performYoutubeSearch(term: term)
                    })
            } else {
                // Could not match youtube id, fallback to search
                performYoutubeSearch(term: term)
            }
        }
    }
    
    private func randomPresetTerm() -> String {
        return HomeViewController.presetTerms[Int(arc4random_uniform(UInt32(HomeViewController.presetTerms.count)))]
    }
    
    func performYoutubeSearch(term: String) {
        Answers.logCustomEvent(withName: "Youtube searched", customAttributes: ["term": term])
        youtube.search(
            term: term,
            success: { (videos: [YoutubeVideo]) -> Void in
                self.youtubeVideos = videos
                self.reloadTable()
            },
            failure: { (error: Error) -> Void in
                self.youtubeVideos = []
                self.reloadTable()
                
                switch error {
                case YoutubeError.unauthorized:
                    if GIDSignIn.sharedInstance().currentUser != nil {
                        GIDSignIn.sharedInstance().signOut()
                        GIDSignIn.sharedInstance().uiDelegate = self
                        GIDSignIn.sharedInstance().delegate = self
                        GIDSignIn.sharedInstance().signIn()
                    }
                    break
                default:
                    print("error: \(error.localizedDescription)")
                }
            })
    }
    
    // Source: http://stackoverflow.com/questions/11509164/
    func extractYoutubeIdFromLink(link: String) -> String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        guard let regExp = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let nsLink = link as NSString
        let options = NSRegularExpression.MatchingOptions(rawValue: 0)
        let range = NSRange(location: 0,length: nsLink.length)
        let matches = regExp.matches(in: link as String, options:options, range:range)
        if let firstMatch = matches.first {
            return nsLink.substring(with: firstMatch.range)
        }
        return nil
    }
    
    
    @IBAction func onViewTapped(_ sender: UITapGestureRecognizer) {
        searchBar.resignFirstResponder()
    }
    @IBAction func onTappedProfile(_ sender: Any) {
        Answers.logCustomEvent(withName: "Tapped profile in home", customAttributes: ["Profile" : PFUser.current()!.objectId!])
        performSegue(withIdentifier: "ProfileSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
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
        case "ProfileSegue":
            let pvc = segue.destination as! ProfileViewController
            if let user = PFUser.current() as? User {
                pvc.user = user
            }
            pvc.delegate = self
        default:
            return
        }
    }
    
    fileprivate func hideSearchMode() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        UIApplication.shared.statusBarStyle = .default
        fadeSearchMode(toOpacity: 0.0)
        segmentedControlBackground.isHidden = true
    }
    
    fileprivate func showSearchMode() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.shared.statusBarStyle = .lightContent
        fadeSearchMode(toOpacity: 1.0)
        segmentedControlBackground.isHidden = false
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
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if joompedTableView.contentOffset.y <= -25 {
            showSearchMode()
        } else if let lastContentOffset = lastContentOffset, lastContentOffset < scrollView.contentOffset.y { //Down Scroll
            hideSearchMode()
        }
        lastContentOffset = scrollView.contentOffset.y
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
       withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y < -1 {
            showSearchMode()
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
        let cell = tableView.cellForRow(at: indexPath)
        if let cell = cell as? JoompedTableViewCell {
            selectedThumbnail = cell.videoImageView
        } else if let cell = cell as? YoutubeVideoTableViewCell {
            selectedThumbnail = cell.videoImageView
        }
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
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            //Selector needed to resign correctly
            searchBar.performSelector(onMainThread: #selector(resignFirstResponder), with: nil, waitUntilDone: false)
            search()
        }
    }
}

extension HomeViewController: ProfileViewControllerDelegate {
    
    func profileViewController(_ profileViewController: ProfileViewController, didDeleteJoomped joomped: Joomped) {
        let index = ParseUtility.indexOf(objects: self.joomped, element: joomped)
        if index != -1 {
            self.joomped.remove(at: index)
            joompedTableView.reloadData()
        }
    }
}

extension HomeViewController: ASFSharedViewTransitionDataSource {
    func sharedView() -> UIView! {
        return selectedThumbnail
    }
}

extension HomeViewController: GIDSignInUIDelegate {
}

extension HomeViewController: GIDSignInDelegate {
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        search(forceRefresh: true)
    }
}

fileprivate enum SearchMode: Int {
    case joomped = 0
    case youtube = 1
    
    var text: String {
        switch self {
        case .joomped:
            return "What would you like to learn?"
        case .youtube:
            return "Youtube link or search term"
        }
    }
}
