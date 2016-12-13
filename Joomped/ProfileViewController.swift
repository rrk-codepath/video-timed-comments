import UIKit
import GoogleSignIn
import Parse
import iOSSharedViewTransition
import FTIndicator

protocol ProfileViewControllerDelegate: class {
    
    func profileViewController(_ profileViewController: ProfileViewController, didDeleteJoomped: Joomped)
}

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var annotatedVideosLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var joompedTableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    @IBOutlet weak var karmaCountLabel: UILabel!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var notatesSegmentedControl: UISegmentedControl!
    
    fileprivate var joomped: [Joomped] = []
    fileprivate var selectedJoomped: Joomped?
    fileprivate var selectedThumbnail: UIImageView?
    fileprivate var isCurrentUser: Bool!
    fileprivate var notatesMode: NotatesMode = NotatesMode.profile
    
    weak var delegate: ProfileViewControllerDelegate?
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ASFSharedViewTransition.addWith(fromViewControllerClass: ProfileViewController.self, toViewControllerClass: JoompedViewController.self, with: self.navigationController, withDuration: 0.3)
        
        guard let user = user else {
            return
        }
        
        isCurrentUser = user == PFUser.current()
        
        if !isCurrentUser {
            logoutButton.rrk_hide()
        }
        
        if let imageUrl = user.imageUrl,
            let url = URL(string: imageUrl) {
            profileImageView.setImageWith(url)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "Person")
        }
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2;
        profileImageView.layer.masksToBounds = true;
        profileImageView.layer.borderWidth = 0;
        
        displayNameLabel.text = user.displayName
        
        joompedTableView.register(UINib(nibName: "JoompedTableViewCell", bundle: nil), forCellReuseIdentifier: "Joomped")
        joompedTableView.dataSource = self
        joompedTableView.delegate = self
        joompedTableView.estimatedRowHeight = 114
        joompedTableView.rowHeight = 114
        joompedTableView.tableFooterView = UIView()

        fetchJoomped();
    }

    @IBAction func onTappedLogout(_ sender: Any) {
        PFUser.logOutInBackground { (error: Error?) in
            GIDSignIn.sharedInstance().signOut()
            self.performSegue(withIdentifier: "LogoutSegue", sender: self)
        }
    }
    
    private func fetchJoomped() {
        let query = PFQuery(className:"Joomped")
        query.order(byDescending: "createdAt")
        query.includeKeys(["video", "user", "annotations.Annotation"])
        query.whereKey("user", equalTo: user as Any)
        
        FTIndicator.showProgressWithmessage("")
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            self.joomped = objects as? [Joomped] ?? []
            if self.joomped.count == 0 {
                self.joompedTableView.isHidden = true
                self.emptyStateLabel.isHidden = false
            } else {
                self.joompedTableView.reloadData()
            }
            
            var joompedCountString = "\(self.joomped.count) notates"
            if self.joomped.count == 1 {
                joompedCountString = joompedCountString.substring(to: joompedCountString.index(before: joompedCountString.endIndex))
            }
            self.annotatedVideosLabel.text = joompedCountString
            
            let viewCount = self.joomped.reduce(0) {
                $0 + $1.views
            }
            let viewCountString = viewCount == 1 ? "view" : "views"
            self.viewCountLabel.text = "\(viewCount) \(viewCountString)"
            
            let karmaCount = self.joomped.reduce(0) {
                $0 + ($1.karma ?? 0)
            }
            self.karmaCountLabel.text = String(karmaCount)
            FTIndicator.dismissProgress()
        }
    }
    
    private func fetchKarmaJoomped() {
        self.joomped = (user?.gaveKarma)!
        FTIndicator.showProgressWithmessage("")
        DispatchQueue.global(qos: .userInitiated).async {
            var fullJoomped: [Joomped] = []
            self.joomped.forEach { (joomp) in
                do {
                    let joomp = try joomp.fetchIfNeeded()
                    try joomp.video.fetchIfNeeded()
                    try joomp.annotations.forEach({ (annotation) in
                        try annotation.fetchIfNeeded()
                    })
                    try joomp.user.fetchIfNeeded()
                    fullJoomped.append(joomp)
                } catch {
//                    print("error retrieving karma joomp \(joomp.objectId)")
                }
            }
            DispatchQueue.main.async {
                self.joomped = fullJoomped
                FTIndicator.dismissProgress()
                self.joompedTableView.reloadData()
            }
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ConsumptionSegue" {
            let jvc = segue.destination as! JoompedViewController
            jvc.joomped = selectedJoomped
        }
    }
    
    fileprivate func delete(index: Int) {
        let toDelete = joomped[index]
        let allToDelete: [PFObject] = toDelete.annotations + [toDelete.video, toDelete]
        PFObject.deleteAll(inBackground: allToDelete)
        joomped.remove(at: index)
        joompedTableView.reloadData()
        delegate?.profileViewController(self, didDeleteJoomped: toDelete)
    }
    
    @IBAction func onFilterNotatesChanged(_ sender: UISegmentedControl) {
        notatesMode = NotatesMode(rawValue: sender.selectedSegmentIndex)!
        notatesMode == .profile ? fetchJoomped() : fetchKarmaJoomped()
    }
}

extension ProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Joomped") as! JoompedTableViewCell
        cell.joomped = joomped[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return joomped.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delete(index: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isCurrentUser
    }
}

extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedJoomped = joomped[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! JoompedTableViewCell
        selectedThumbnail = cell.videoImageView
        
        performSegue(withIdentifier: "ConsumptionSegue", sender: self)
    }
}

extension ProfileViewController: ASFSharedViewTransitionDataSource {
    func sharedView() -> UIView! {
        return selectedThumbnail
    }
}

fileprivate enum NotatesMode: Int {
    case profile = 0
    case karma = 1
}
