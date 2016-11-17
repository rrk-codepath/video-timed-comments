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

class JoompedViewController: UIViewController {

    @IBOutlet weak var videoTitleLabel: UILabel!
    @IBOutlet weak var videoUploaderLabel: UILabel!
    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var liveAnnotationLabel: UILabel!
    @IBOutlet weak var joompedUploaderLabel: UILabel?
    
    var joomped: Joomped?
    var youtubeVideo: YoutubeVideo?
    fileprivate var annotations = [Annotation]()
    fileprivate var annotationTime: Float?
    fileprivate var annotationsDict = [Float:Annotation]()
    fileprivate var timer: Timer = Timer()
    var isEditMode = false {
        didSet {
            updateNavigationBar()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
        playerView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        let playerVars = [
            "playsinline": 1
        ]
        if let joomped = joomped {
            annotations = joomped.annotations
            videoTitleLabel.text = joomped.video.title
            videoUploaderLabel.text = joomped.video.author
            joompedUploaderLabel?.text = joomped.user.username
            playerView.load(withVideoId: joomped.video.youtubeId, playerVars: playerVars)
        } else if let youtubeVideo = youtubeVideo {
            videoTitleLabel.text = youtubeVideo.snippet.title
            videoUploaderLabel.text = youtubeVideo.snippet.channelTitle
            playerView.load(withVideoId: youtubeVideo.id, playerVars: playerVars)
            joompedUploaderLabel?.isHidden = true
        }
        annotations.forEach { (annotation) in
            self.annotationsDict[floorf(annotation.timestamp)] = annotation
            self.annotationsDict[ceilf(annotation.timestamp)] = annotation
        }
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "AnnotationCell", bundle: nil), forCellReuseIdentifier: "AnnotationCell")
        liveAnnotationLabel.text = ""
        updateNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func didTapEditSave(_ sender: UIBarButtonItem) {
        if !isEditMode {
            isEditMode = true
            tableView.reloadData()
            return
        }
        guard let user = PFUser.current() as? User else {
            return
        }
        let newJoomped = joomped ?? Joomped()
        
        let video = joomped?.video ?? Video()
        
        if let youtubeVideo = youtubeVideo {
            video.youtubeId = youtubeVideo.id
            video.length = playerView.duration()
            video.title = youtubeVideo.snippet.title
            video.author = youtubeVideo.snippet.channelTitle
            video.thumbnail = youtubeVideo.snippet.thumbnail.url
        }
    
        newJoomped.annotations = annotations
        newJoomped.user = user
        newJoomped.video = video
        newJoomped.saveInBackground { (success: Bool, error: Error?) in
            if let error = error {
                print("error saving \(error.localizedDescription)")
                return
            }
            print("saved successfully: \(newJoomped.objectId)")
            self.playerView.stopVideo()
            self.performSegue(withIdentifier: "saveHomeSegue", sender: self)
        }
    }
    
    func updateNavigationBar() {
        guard let user = PFUser.current() else {
            return
        }
        if isEditMode && (youtubeVideo != nil && joomped == nil || joomped?.user.objectId == user.objectId){
            navigationItem.title = "Creation"
            navigationItem.rightBarButtonItem?.title = "Save"
            if annotations.count == 0 {
                navigationItem.rightBarButtonItem?.isEnabled = false
            }
        } else if (joomped?.user.objectId == user.objectId) {
            navigationItem.title = "Consumption"
            navigationItem.rightBarButtonItem?.title = "Edit"
        } else {
            navigationItem.title = "Consumption"
            hideRightBarButtonItem()
        }
    }
    
    func hideRightBarButtonItem() {
        navigationItem.rightBarButtonItem?.rrk_hide()
    }

    func setAnnotationLabel() {
        self.liveAnnotationLabel?.text = ""
    }
}


extension JoompedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return annotations.count
        } else if (section == 1) {
            return 1
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isEditMode {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnnotationCell") as! AnnotationCell
        cell.delegate = self
        
        if indexPath.section == 0 {
            let annotation = annotations[indexPath.row]
            cell.annotation = annotation
            cell.isEditMode = false
        } else if indexPath.section == 1 && isEditMode {
            cell.annotation = nil
            cell.timestampLabel.isHidden = true
        }
        return cell
    }
}

extension JoompedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let annotation = Annotation(text: "", timestamp: self.playerView.currentTime())
            let cell = tableView.cellForRow(at: indexPath) as! AnnotationCell
            cell.annotation = annotation
        }
    }
    
}

extension JoompedViewController: AnnotationCellDelegate {
    
    func annotationCell(annotationCell: AnnotationCell, addedAnnotation newAnnotation: Annotation) {
        if annotations.count == 0 || newAnnotation.timestamp > annotations.last!.timestamp {
            // insert at end if no annotations, or the new annotation has the largest timestamp
            annotations.append(newAnnotation)
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            for (index, annotation) in annotations.enumerated() {
                if newAnnotation.timestamp < annotation.timestamp {
                    annotations.insert(newAnnotation, at: index)
                }
            }
        }
        print("Number of annotations: \(annotations.count)")
        annotations.forEach { (annotation) in
            annotationsDict[floorf(annotation.timestamp)] = annotation
            annotationsDict[ceilf(annotation.timestamp)] = annotation
        }
        tableView?.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let numberOfSections = self.tableView.numberOfSections
            let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections - 1)
            let indexPath = IndexPath(item: numberOfRows - 1, section: numberOfSections - 1)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    func annotationCell(annotationCell: AnnotationCell, tappedTimestamp timestamp: Float) {
        self.playerView?.seek(toSeconds: timestamp, allowSeekAhead: true)
    }
}

extension JoompedViewController: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.playVideo()
    }
    
    //Called roughly every half second
    //TODO: Can't create annotations within 2 seconds apart..., but also don't want to keep firing same annotation timer due to floor/ceil
    //Need floor/ceil as not every annotation shows up when tapped
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        if !timer.isValid {
            if let annotation = annotationsDict[floor(playTime)] {
                liveAnnotationLabel?.text = annotation.text
                timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(setAnnotationLabel), userInfo: nil, repeats: false)
            }
        }
    }
}