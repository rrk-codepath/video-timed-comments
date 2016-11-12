//
//  SearchYouTubeViewController.swift
//  Joomped
//
//  Created by R-J Lim on 11/11/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit

class SearchYoutubeViewController: UIViewController {

    @IBOutlet weak var youtubeTableView: UITableView!
    
    fileprivate var videos: [YoutubeVideo] = []

    private let youtube = Youtube()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Should replace this with recently watched or something
        youtube.search(
            term: "philosophy lectures",
            success: { (videos: [YoutubeVideo]) -> Void in
                self.videos = videos
                self.youtubeTableView.reloadData()
            },
            failure: nil
        )
    }
}

extension SearchYoutubeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
}
