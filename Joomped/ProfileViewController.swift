import UIKit
import GoogleSignIn
import Parse

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var annotatedVideosLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var joompedTableView: UITableView!
    
    fileprivate var joomped: [Joomped] = []
    fileprivate var selectedJoomped: Joomped?
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = user else {
            return
        }
        
        if let url = URL(string: user.imageUrl ?? "https://placekitten.com/g/100/100") {
            profileImageView.setImageWith(url)
        }
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2;
        profileImageView.layer.masksToBounds = true;
        profileImageView.layer.borderWidth = 0;
        
        displayNameLabel.text = user.displayName
        
        joompedTableView.register(UINib(nibName: "JoompedTableViewCell", bundle: nil), forCellReuseIdentifier: "Joomped")
        joompedTableView.dataSource = self
        joompedTableView.delegate = self
        joompedTableView.estimatedRowHeight = 50
        joompedTableView.rowHeight = UITableViewAutomaticDimension
        
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
        query.includeKey("annotations.Annotation")
        query.order(byDescending: "createdAt")
        query.includeKeys(["video", "user"])
        query.whereKey("user", equalTo: user as Any)
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            self.joomped = objects as? [Joomped] ?? []
            self.joompedTableView.reloadData()
            
            self.annotatedVideosLabel.text = "\(self.joomped.count) annotated videos"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let jvc = segue.destination as! JoompedViewController
        jvc.joomped = selectedJoomped
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
}

extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedJoomped = joomped[indexPath.row]
        performSegue(withIdentifier: "ConsumptionSegue", sender: self)
    }
}
