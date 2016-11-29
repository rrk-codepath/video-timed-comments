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
    @IBOutlet weak var joompedUploaderButton: UIButton!
    @IBOutlet weak var publishLabel: UILabel!
    @IBOutlet weak var numberAnnotationsLabel: UILabel!
    @IBOutlet weak var seekBarView: UIView!
    @IBOutlet weak var seekBar: UIView!
    @IBOutlet weak var liveAnnotationBlurView: UIVisualEffectView!
    @IBOutlet weak var playerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var seekBarToPlayerViewSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var fullscreenButton: UIButton!
    
    var currentAnnotation: Annotation?
    var currentAnnotationCell: AnnotationCell?
    var joomped: Joomped?
    var joompedId: String? {
        didSet {
            guard let joompedId = joompedId else {
                return
            }
            let query = PFQuery(className:"Joomped")
            query.includeKeys(["video", "user", "annotations.Annotation"])
            query.whereKey("objectId", equalTo: joompedId)
            query.getFirstObjectInBackground { (object: PFObject?, error: Error?) in
                if let error = error {
                    print("error: \(error.localizedDescription)")
                    return
                }
                self.joomped = object as? Joomped ?? nil
                self.configureView()
                self.tableView.reloadData()
            }
        }
    }
    var youtubeVideo: YoutubeVideo?
    fileprivate var annotations = [Annotation]()
    fileprivate var annotationTime: Float?
    fileprivate var annotationsDict = [Float:Annotation]()
    fileprivate var timer: Timer = Timer()
    fileprivate var isSeekBarAnnotated = false
    fileprivate var duration: Float?
    fileprivate var seekBarLine: UIView?
    
    private var fullscreen = false

    var isEditMode = false {
        didSet {
            configureNavigationBar()
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
        UIApplication.shared.statusBarStyle = .lightContent
        
        liveAnnotationBlurView.alpha = 0.50
        liveAnnotationBlurView.layer.cornerRadius = 5
        liveAnnotationBlurView.layer.masksToBounds = true
        liveAnnotationBlurView.clipsToBounds = true
        
        playButton.tintColor = UIColor.rrk_primaryColor
        fullscreenButton.tintColor = UIColor.rrk_primaryColor
        
        let playerVars = [
            "playsinline": 1,
            "controls": 0,
            "rel": 0,
            "showinfo": 0,
            "fs": 0,
            "iv_load_policy": 3
        ]
        
        playerViewHeightConstraint.constant = playerView.frame.width * 9.0 / 16.0
        
        self.automaticallyAdjustsScrollViewInsets = false
        seekBar.backgroundColor = UIColor.rrk_secondaryColor

        if let joomped = joomped {
            duration = Float(joomped.video.length)
            annotations = joomped.annotations
            videoTitleLabel.text = joomped.video.title
            videoUploaderLabel.text = joomped.video.author
            joompedUploaderButton.setTitle(joomped.user.displayName, for: .normal)
            var countString = "\(joomped.annotations.count) annotations"
            if joomped.annotations.count == 1 {
                countString = countString.substring(to: countString.index(before: countString.endIndex))
            }
            numberAnnotationsLabel.text = countString
            numberAnnotationsLabel.isHidden = false
            publishLabel.text = joomped.createdAt?.timeFormatted
            publishLabel.isHidden = false
            playerView.load(withVideoId: joomped.video.youtubeId, playerVars: playerVars)
        } else if let youtubeVideo = youtubeVideo {
            videoTitleLabel.text = youtubeVideo.snippet.title
            videoUploaderLabel.text = youtubeVideo.snippet.channelTitle
            playerView.load(withVideoId: youtubeVideo.id, playerVars: playerVars)
            joompedUploaderButton.isHidden = true
        }
        annotations.forEach { (annotation) in
            self.annotationsDict[floorf(annotation.timestamp)] = annotation
            self.annotationsDict[ceilf(annotation.timestamp)] = annotation
            updateAnnotationInSeekBar()
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "AnnotationCell", bundle: nil), forCellReuseIdentifier: "AnnotationCell")
        liveAnnotationLabel.text = ""
        configureNavigationBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            onLandscape()
        }
        playButton.isEnabled = false
        fullscreenButton.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let headerView = tableView.tableHeaderView!
        headerView.setNeedsLayout()
        tableView.layoutIfNeeded()
        // This is a hack in order to adjust the header height according to the contents
        // Source: http://roadfiresoftware.com/2015/05/how-to-size-a-table-header-view-using-auto-layout-in-interface-builder/
        let height = videoTitleLabel.frame.height + publishLabel.frame.height + videoUploaderLabel.frame.height + 30
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame
        tableView.tableHeaderView = headerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func unhighlightVisbileCells() {
        tableView.visibleCells.forEach({ (cell) in
            if cell != currentAnnotationCell {
                cell.backgroundColor = UIColor.white
            }
        })
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
    
    @IBAction func didTapJoompedUser(_ sender: Any) {
        performSegue(withIdentifier: "ProfileSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        switch segue.identifier! {
        case "ProfileSegue":
            let pvc = segue.destination as! ProfileViewController
            if let joomped = joomped {
                pvc.user = joomped.user
            }
        default:
            return
        }
    }
    
    @IBAction func didTapShare(_ sender: UIBarButtonItem) {
        guard let joompedObjectId = joomped?.objectId else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: ["joomped://joomp/\(joompedObjectId)"], applicationActivities: nil)
        navigationController?.present(activityViewController, animated: true)
    }
    
    func configureNavigationBar() {
        guard let user = PFUser.current() else {
            return
        }
        var rightBarButtonItems = [UIBarButtonItem]()
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(JoompedViewController.didTapShare(_:)))
        
        let actionButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(JoompedViewController.didTapEditSave(_:)))
        
        if isEditMode && (youtubeVideo != nil && joomped == nil || joomped?.user.objectId == user.objectId){
            navigationItem.title = "Creation"
            actionButton.title = "Save"
            if annotations.count == 0 {
                actionButton.isEnabled = false
            }
            rightBarButtonItems.append(actionButton)
        } else if (joomped?.user.objectId == user.objectId) {
            navigationItem.title = "Consumption"
            rightBarButtonItems.append(actionButton)
            rightBarButtonItems.append(shareButton)
        } else {
            navigationItem.title = "Consumption"
            rightBarButtonItems.append(shareButton)
        }
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    func setAnnotationLabel() {
        self.liveAnnotationLabel?.text = ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func orientationRotated(notification: NSNotification) {
        if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            onLandscape()
        } else {
            onPortrait()
        }
    }
    
    private func onLandscape() {
        displayFullscreen(fullscreen: true)
        fullscreenButton.isEnabled = false
    }
    
    private func onPortrait() {
        displayFullscreen(fullscreen: fullscreen)
        fullscreenButton.isEnabled = true
    }
    
    func updateAnnotationInSeekBar() {
        seekBar.subviews.forEach({ $0.removeFromSuperview() })
        annotations.forEach { (annotation) in
            let percentage = annotation.timestamp / (duration ?? Float(playerView.duration()))
            let lineView = UIView(frame: CGRect(x: Double(Float(seekBar.bounds.width) * percentage), y: -5, width: 3, height: Double(15)))
            lineView.backgroundColor = UIColor.rrk_primaryColor
            seekBar.addSubview(lineView)
        }
        isSeekBarAnnotated = true
    }
    
    func updateSeekBarLine(percentage: Float? = nil) {
        seekBarLine?.removeFromSuperview()
        var percentageOfVideo = percentage ?? playerView.currentTime() / (duration ?? Float(playerView.duration()))
        if percentageOfVideo > 1 {
            percentageOfVideo = 1
        } else if percentageOfVideo < 0 {
            percentageOfVideo = 0
        }
        seekBarLine = UIView(frame: CGRect(x: Double(Float(seekBar.bounds.width) * percentageOfVideo) - 5, y: -5, width: 14, height: 14))
        seekBarLine?.layer.cornerRadius = 10
        seekBarLine?.backgroundColor = UIColor.red
        seekBar.addSubview(seekBarLine!)
    }
    
    @IBAction func didPanSeekBar(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self.seekBar)
        let percentageOfVideo = Float(location.x / self.seekBar.bounds.width)
        updateSeekBarLine(percentage: percentageOfVideo)
        playerView.seek(toSeconds: Float(playerView.duration()) * percentageOfVideo , allowSeekAhead: true)
        
    }
    
    @IBAction func onPlayTapped(_ sender: Any) {
        if playerView.playerState() == YTPlayerState.playing {
            playButton.setImage(#imageLiteral(resourceName: "Play"), for: UIControlState.normal)
            playerView.pauseVideo()
        } else {
            playerView.playVideo()
            // Should eventually be replaced with an icon
            playButton.setImage(#imageLiteral(resourceName: "Pause"), for: UIControlState.normal)
        }
    }
    
    @IBAction func onFullscreenTapped(_ sender: Any) {
        fullscreen = !fullscreen
        if !UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            displayFullscreen(fullscreen: fullscreen)
        }
    }
    
    private func displayFullscreen(fullscreen: Bool) {
        self.navigationController?.setNavigationBarHidden(fullscreen, animated: true)
        UIApplication.shared.isStatusBarHidden = fullscreen
        if fullscreen {
            animate(constraint: playerViewHeightConstraint, toConstant: view.frame.height)
            animate(constraint: seekBarToPlayerViewSpaceConstraint, toConstant: -50)
            self.fullscreenButton.setImage(#imageLiteral(resourceName: "Compress"), for: .normal)
        } else {
            animate(constraint: playerViewHeightConstraint, toConstant: playerView.frame.width * 9 / 16)
            animate(constraint: seekBarToPlayerViewSpaceConstraint, toConstant: 0)
            self.fullscreenButton.setImage(#imageLiteral(resourceName: "Full-Screen"), for: .normal)
        }
        updateAnnotationInSeekBar()
    }
    
    private func animate(constraint: NSLayoutConstraint, toConstant constant: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
            constraint.constant = constant
        })
    }
    
    @IBAction func didTapSeekBar(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.seekBar)
        let percentageOfVideo = Float(location.x / self.seekBar.bounds.width)
        updateSeekBarLine(percentage: Float(percentageOfVideo))
        playerView.seek(toSeconds: Float(playerView.duration()) * percentageOfVideo , allowSeekAhead: true)
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
            if let currentAnnotation = currentAnnotation {
                if cell.annotation != currentAnnotation {
                    cell.backgroundColor = UIColor.white
                } else {
                    cell.backgroundColor = UIColor.rrk_primaryColor
                }
            }
            let annotation = annotations[indexPath.row]
            cell.annotation = annotation
            cell.isEditMode = isEditMode
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
            cell.annotationTextView.becomeFirstResponder()
        } else if indexPath.section == 0 {
            let annotationCell = tableView.cellForRow(at: indexPath) as! AnnotationCell
            currentAnnotationCell = annotationCell
            UIView.animate(withDuration: 1, animations: {
                annotationCell.backgroundColor = UIColor.rrk_primaryColor
            })
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            if let timestamp = annotationCell.annotation?.timestamp {
                self.playerView?.seek(toSeconds: timestamp, allowSeekAhead: true)
                let percentage = timestamp / (duration ?? Float(playerView.duration()))
                updateSeekBarLine(percentage: percentage)
            }
            unhighlightVisbileCells()
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
        annotationCell.closeButton.isHidden = false
        print("Number of annotations: \(annotations.count)")
        annotations.forEach { (annotation) in
            annotationsDict[floorf(annotation.timestamp)] = annotation
            annotationsDict[ceilf(annotation.timestamp)] = annotation
        }
        tableView?.reloadData()
        updateAnnotationInSeekBar()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let numberOfSections = self.tableView.numberOfSections
            let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections - 1)
            let indexPath = IndexPath(item: numberOfRows - 1, section: numberOfSections - 1)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    func annotationCell(annotationCell: AnnotationCell, removedAnnotation: Annotation) {
        if let index = annotations.index(of: removedAnnotation) {
            annotations.remove(at: index)
            tableView.reloadData()
            updateAnnotationInSeekBar()
        }
    }
}

extension JoompedViewController: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        guard let videoId = joomped?.video.youtubeId ?? self.youtubeVideo?.id else {
            return
        }
        playerView.cueVideo(byId: videoId, startSeconds: playerView.currentTime(), suggestedQuality: YTPlaybackQuality.medium)
        playerView.playVideo()
        if !isSeekBarAnnotated {
            updateAnnotationInSeekBar()
        }
        playButton.isEnabled = true
        fullscreenButton.isEnabled = true
    }
    
    //Called roughly every half second
    //TODO: Can't create annotations within 2 seconds apart..., but also don't want to keep firing same annotation timer due to floor/ceil
    //Need floor/ceil as not every annotation shows up when tapped
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        updateSeekBarLine()
        if !timer.isValid {
            if let annotation = annotationsDict[floor(playTime)] {
                liveAnnotationLabel?.text = annotation.text
                currentAnnotation = annotation
                if let index = annotations.index(of: annotation) {
                    let indexPath = IndexPath(row: index, section: 0)
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    let currentAnnotationCell = tableView.cellForRow(at: indexPath) as? AnnotationCell
                    UIView.animate(withDuration: 1, animations: {
                        currentAnnotationCell?.backgroundColor = UIColor.rrk_primaryColor
                    })
                    self.currentAnnotationCell = currentAnnotationCell
                    unhighlightVisbileCells()
                }
                
                timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(setAnnotationLabel), userInfo: nil, repeats: false)
            }
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case .playing, .buffering:
            playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        default:
            playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        }
    }
}
