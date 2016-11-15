//
//  HomeViewController.swift
//  Joomped
//
//  Created by Keith Lee on 11/9/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit
import Parse
import youtube_ios_player_helper

class CreationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var videoTitle: UILabel!
    @IBOutlet weak var videoUploader: UILabel!
    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var liveAnnotationLabel: UILabel!
    
    var youtubeVideo: YoutubeVideo!
    var annotations = [Annotation]()
    var annotationTime: Float?
    var annotationsDict = [Float:Annotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let playerVars = [
            "playsinline": 1
        ]
        
        videoTitle.text = youtubeVideo.snippet.title
        videoUploader.text = youtubeVideo.snippet.channelTitle
        
        playerView.delegate = self
        playerView.load(withVideoId: youtubeVideo.id, playerVars: playerVars)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "AnnotationCell", bundle: nil), forCellReuseIdentifier: "AnnotationCell")
        liveAnnotationLabel.text = ""
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return annotations.count
        } else if (section == 1) {
            return 1
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnnotationCell") as! AnnotationCell
        cell.delegate = self
        if indexPath.section == 0 {
            let annotation = annotations[indexPath.row]
            cell.annotation = annotation
            cell.isEditMode = false
        } else {
            cell.annotation = nil
            cell.timestampLabel.isHidden = true
        }
        return cell
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let annotation = Annotation(text: "", timestamp: self.playerView.currentTime())
            let cell = tableView.cellForRow(at: indexPath) as! AnnotationCell
            cell.annotation = annotation
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        print("did tap joomped save")
        guard let user = PFUser.current() as? User else {
            return
        }
        let joomped = Joomped()
        
        
        let video = Video()
        video.youtubeId = youtubeVideo.id
        video.length = playerView.duration()
        video.title = youtubeVideo.snippet.title
        video.author = youtubeVideo.snippet.channelTitle
        video.thumbnail = youtubeVideo.snippet.thumbnail.url
    
        joomped.annotations = annotations
        joomped.user = user
        joomped.video = video
        joomped.saveInBackground { (success: Bool, error: Error?) in
            if let error = error {
                print("error saving \(error.localizedDescription)")
                return
            }
            print("saved successfully: \(joomped.objectId)")
            self.playerView.stopVideo()
            self.performSegue(withIdentifier: "saveHomeSegue", sender: self)
        }
    }
}

extension CreationViewController: AnnotationCellDelegate {
    
    func annotationCell(annotationCell: AnnotationCell, addedAnnotation newAnnotation: Annotation) {
        // TODO: insert in sorted order
        annotations.append(newAnnotation)
        print("Number of annotations: \(annotations.count)")
        annotations.forEach { (annotation) in
            annotationsDict[floorf(annotation.timestamp)] = annotation
        }
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let numberOfSections = self.tableView.numberOfSections
            let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections - 1)
            let indexPath = IndexPath(item: numberOfRows - 1, section: numberOfSections - 1)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    func annotationCell(annotationCell: AnnotationCell, tappedTimestamp timestamp: Float) {
        self.playerView.seek(toSeconds: timestamp, allowSeekAhead: true)
    }
}

extension CreationViewController: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.playVideo()
    }
    
    //Called roughly every half second
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        if let annotation = annotationsDict[floor(playTime)] {
            liveAnnotationLabel.text = annotation.text
        }
    }
}
