import UIKit
import GoogleSignIn

final class SearchYoutubeViewController: UIViewController {

    @IBOutlet weak var youtubeTableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    fileprivate var videos: [YoutubeVideo] = []
    fileprivate var selectedVideo: YoutubeVideo?

    private let youtube = Youtube()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        youtubeTableView.register(UINib(nibName: "YoutubeVideoTableViewCell", bundle: nil), forCellReuseIdentifier: "YoutubeVideo")
        youtubeTableView.dataSource = self
        youtubeTableView.delegate = self
        youtubeTableView.estimatedRowHeight = 50
        youtubeTableView.rowHeight = UITableViewAutomaticDimension
        
        searchBar.delegate = self
        searchBar.text = "Pokemon Lectures"
        
        search()
    }
    
    fileprivate func search() {
        guard let term = searchBar.text, !term.isEmpty else {
            return
        }
        
        youtube.search(
            term: term,
            success: { (videos: [YoutubeVideo]) -> Void in
                self.videos = videos
                self.youtubeTableView.reloadData()
        },
            failure: { (error: Error) -> Void in
                print("error: \(error.localizedDescription)")
            }
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let joompedViewController = segue.destination as? JoompedViewController else {
            return
        }
        
        joompedViewController.youtubeVideo = selectedVideo
        joompedViewController.isEditMode = true
    }
}

extension SearchYoutubeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "YoutubeVideo") as! YoutubeVideoTableViewCell
        cell.youtubeVideo = videos[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
}

extension SearchYoutubeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedVideo = videos[indexPath.row]
        performSegue(withIdentifier: "Creation", sender: self)
    }
}

extension SearchYoutubeViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        search()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
        searchBar.resignFirstResponder()
    }
}
