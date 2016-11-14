//
//  ConsumptionViewController.swift
//  Joomped
//
//  Created by Keith Lee on 11/14/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit
import youtube_ios_player_helper

class ConsumptionViewController: UIViewController {
    
    @IBOutlet weak var videoTitle: UILabel!
    @IBOutlet weak var videoUploader: UILabel!
    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var joompedUploader: UILabel!
    
    var joomped: Joomped!
    
    fileprivate var annotations: [Annotation] {
        get {
            return joomped.annotations
        }
        set {
            joomped.annotations = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "AnnotationCell", bundle: nil), forCellReuseIdentifier: "AnnotationCell")
        
        videoTitle.text = joomped.video.title
        videoUploader.text = joomped.video.author
        joompedUploader.text = joomped.user.username
        let playerVars = [
            "playsinline": 1
        ]
        playerView.delegate = self
        playerView.load(withVideoId: joomped.video.youtubeId, playerVars: playerVars)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension ConsumptionViewController: AnnotationCellDelegate {
    func annotationCell(annotationCell: AnnotationCell, tappedTimestamp timestamp: Float) {
        playerView.seek(toSeconds: timestamp, allowSeekAhead: true)
    }
}

extension ConsumptionViewController: YTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.playVideo()
    }
}

extension ConsumptionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnnotationCell") as! AnnotationCell
        cell.annotation = annotations[indexPath.row]
        cell.isEditMode = false
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return annotations.count 
    }
}


