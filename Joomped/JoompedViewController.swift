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
import iOSSharedViewTransition
import FTIndicator

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
    @IBOutlet weak var karmaLabel: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var karmaCountLabel: UILabel!
    @IBOutlet weak var joompedUploaderImageView: UIImageView!
    
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
    //First time creation
    var segueToHomeFlag: Bool {
        get {
            return joomped == nil
        }
    }
    
    fileprivate var annotations = [Annotation]()
    fileprivate var annotationTime: Float?
    fileprivate var annotationsDict = [Float:Annotation]()
    fileprivate var timer: Timer = Timer()
    fileprivate var isSeekBarAnnotated = false
    fileprivate var duration: Float?
    fileprivate var seekBarLine: UIView?
    fileprivate var highlightedRow: Int?
    
    private var youtubeStoryboard: YoutubeStoryboard!
    private var fullscreen = false

    var isEditMode = false {
        didSet {
            configureNavigationBar()
            FTIndicator.dismissProgress()
            tableView?.reloadData()
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
        
        playButton.tintColor = UIColor.rrk_secondaryColor
        fullscreenButton.tintColor = UIColor.rrk_secondaryColor

        let playerVars = [
            "playsinline": 1,
            "controls": 0,
            "rel": 0,
            "showinfo": 0,
            "fs": 0,
            "iv_load_policy": 3,
            "modestbranding": 1,
            "origin": "https://www.example.com"
        ] as [String : Any]
        
        playerViewHeightConstraint.constant = UIScreen.main.bounds.width * 9.0 / 16.0

        self.automaticallyAdjustsScrollViewInsets = false
        seekBar.backgroundColor = UIColor.rrk_secondaryColor

        if let joomped = joomped {
            if let karma = joomped.karma {
                karmaCountLabel.text = String(karma)
            } else {
                karmaCountLabel.text = "0"
            }
            if let user = PFUser.current() as? User {
                if ParseUtility.contains(objects: user.gaveKarma, element: joomped) {
                    likeButton.tintColor = UIColor.red
                } else {
                    likeButton.tintColor = UIColor.lightGray
                }
            }
            duration = Float(joomped.video.length)
            annotations = joomped.annotations
            videoTitleLabel.text = joomped.video.title
            videoUploaderLabel.text = joomped.video.author
            joompedUploaderButton.setTitle(joomped.user.displayName, for: .normal)
            if let imageUrl = joomped.user.imageUrl,
                let url = URL(string: imageUrl) {
                joompedUploaderImageView.setImageWith(url)
            } else {
                joompedUploaderImageView.image = #imageLiteral(resourceName: "Person")
            }
            
            joompedUploaderImageView.layer.cornerRadius = joompedUploaderImageView.frame.width / 2
            joompedUploaderImageView.clipsToBounds = true
            
            var countString = "\(joomped.annotations.count) jumps"
            if joomped.annotations.count == 1 {
                countString = countString.substring(to: countString.index(before: countString.endIndex))
            }
            numberAnnotationsLabel.text = countString
            numberAnnotationsLabel.isHidden = false
            publishLabel.text = joomped.createdAt?.timeFormatted
            publishLabel.isHidden = false
            playerView.load(withVideoId: joomped.video.youtubeId, playerVars: playerVars)
            joomped.views += 1
            joomped.saveInBackground()
            
            youtubeStoryboard = YoutubeStoryboard(videoId: joomped.video.youtubeId)
        } else if let youtubeVideo = youtubeVideo {
            likeButton.removeFromSuperview()
            karmaLabel.removeFromSuperview()
            publishLabel.removeFromSuperview()
            numberAnnotationsLabel.removeFromSuperview()
            karmaCountLabel.removeFromSuperview()
            joompedUploaderImageView.removeFromSuperview()
            
            videoTitleLabel.text = youtubeVideo.snippet.title
            videoTitleLabel.textColor = UIColor.black
            videoUploaderLabel.text = youtubeVideo.snippet.channelTitle
            playerView.load(withVideoId: youtubeVideo.id, playerVars: playerVars)
            joompedUploaderButton.isHidden = true
            
            youtubeStoryboard = YoutubeStoryboard(videoId: youtubeVideo.id)
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
        var height: CGFloat
        //First time creation
        if segueToHomeFlag {
            height = videoTitleLabel.frame.height + videoUploaderLabel.frame.height + 20
        } else {
            height = videoTitleLabel.frame.height + publishLabel.frame.height + videoUploaderLabel.frame.height + joompedUploaderImageView.frame.height + 70
        }
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame
        tableView.tableHeaderView = headerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateAnnotationInSeekBar()
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
        newJoomped.views = joomped?.views ?? 0
        FTIndicator.showProgressWithmessage("")
        newJoomped.saveInBackground { (success: Bool, error: Error?) in
            FTIndicator.dismissProgress()
            if let error = error {
                let alert = UIAlertController(title: "Error with save",
                                              message: error.localizedDescription,
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                let cancelAction = UIAlertAction(title: "OK",
                                                 style: .cancel, handler: nil)
                
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            if self.segueToHomeFlag {
                self.playerView.stopVideo()
                self.performSegue(withIdentifier: "saveHomeSegue", sender: self)
            } else {
                self.isEditMode = false
            }
        }
    }
    
    @IBAction func didTapLikeButton(_ sender: UITapGestureRecognizer) {
        guard let user = PFUser.current() as? User else {
            print("failed to get User object")
            return
        }
        guard let joomped = joomped else {
            return
        }
        if joomped.karma == nil {
            joomped.karma = 0
        }
        var newKarmaCount: Int
        var tintColor: UIColor
        let index = ParseUtility.indexOf(objects: user.gaveKarma, element: joomped)
        if index != -1 {
            // unlike
            user.gaveKarma.remove(at: index)
            newKarmaCount = joomped.karma! - 1
            tintColor = UIColor.lightGray
        } else {
            // like
            user.gaveKarma.append(joomped)
            newKarmaCount = joomped.karma! + 1
            tintColor = UIColor.red
        }
        joomped.karma = newKarmaCount
        karmaCountLabel.text = String(newKarmaCount)
        let tintedImage = likeButton.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        likeButton.image = tintedImage
        likeButton.tintColor = tintColor
        likeButton.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        UIView.animate(
            withDuration: 2.0,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 6.0,
            options: .allowUserInteraction,
            animations: {[weak self] in
                self?.likeButton.transform = .identity
            },
            completion: nil)
        joomped.saveInBackground()
        user.saveInBackground()
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
            navigationItem.title = "Joomped"
            rightBarButtonItems.append(actionButton)
            rightBarButtonItems.append(shareButton)
        } else {
            navigationItem.title = "Joomped"
            rightBarButtonItems.append(shareButton)
        }
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    func setAnnotationLabel() {
        self.liveAnnotationLabel?.text = ""
        highlightedRow = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight + 24, 0)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: { self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0) })
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
            let duration = self.duration ?? Float(playerView.duration())
            if duration == 0 {
                return
            }
            let percentage = annotation.timestamp / duration
            let lineView = UIView(frame: CGRect(x: Double(Float(seekBar.bounds.width) * percentage), y: -5, width: 3, height: Double(15)))
            lineView.backgroundColor = UIColor.rrk_primaryColorSelected
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
    
    private func updateSeekBar(location: CGPoint) {
        let percentageOfVideo = Float(location.x / self.seekBar.bounds.width)
        updateSeekBarLine(percentage: percentageOfVideo)
        playerView.seek(toSeconds: Float(playerView.duration()) * percentageOfVideo , allowSeekAhead: true)
    }
    
    @IBAction func didPanSeekBar(_ recognizer: UIPanGestureRecognizer) {
        updateSeekBar(location: recognizer.location(in: self.seekBar))
    }
    
    @IBAction func didTapSeekBar(_ recognizer: UITapGestureRecognizer) {
        updateSeekBar(location: recognizer.location(in: self.seekBar))
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
    
    fileprivate func displayThumbnail(forCell cell: AnnotationCell) {
        guard let timestamp = cell.annotation?.timestamp, let duration = duration else {
            return
        }
        youtubeStoryboard.getThumbnail(
            progress: timestamp / duration,
            callback: { (url: URL, location: YoutubeStoryboard.Location) in
                cell.thumbnailImageView.setImageWith(URLRequest(url: url), placeholderImage: nil, success: { (request: URLRequest, response: HTTPURLResponse?, image: UIImage) in
                    let widthScale: CGFloat = 1.0 / CGFloat(self.youtubeStoryboard.columns)
                    let heightScale: CGFloat = 1.0 / CGFloat(self.youtubeStoryboard.rows)
                    let xLocation = CGFloat(location.column) / CGFloat(self.youtubeStoryboard.columns)
                    let yLocation = CGFloat(location.row) / CGFloat(self.youtubeStoryboard.rows)
                    cell.thumbnailImageView.layer.contentsRect = CGRect(x: xLocation, y: yLocation, width: widthScale, height: heightScale)
                    cell.thumbnailImageView.image = image
                    cell.showThumbnail()
                }, failure: nil)
            },
            failure: { () -> Void in
                cell.hideThumbnail()
            }
        )
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEditMode && indexPath.section == 0 ? true : false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! AnnotationCell
            if let index = annotations.index(of: cell.annotation!) {
                annotations.remove(at: index)
                tableView.reloadData()
                updateAnnotationInSeekBar()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnnotationCell") as! AnnotationCell
        cell.delegate = self
        
        if indexPath.section == 0 {
            if highlightedRow == indexPath.row {
                cell.backgroundColor = UIColor.rrk_highlightColor
            } else {
                cell.backgroundColor = UIColor.white
            }
            let annotation = annotations[indexPath.row]
            cell.annotation = annotation
            cell.isEditMode = isEditMode
            displayThumbnail(forCell: cell)
        } else if indexPath.section == 1 && isEditMode {
            cell.isNew = true
            cell.annotation = nil
            cell.timestampLabel.isHidden = true
            cell.thumbnailImageView.image = nil
        }
        return cell
    }
}

extension JoompedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! AnnotationCell
        if isEditMode {
            self.playerView.pauseVideo()
            cell.annotationTextView.becomeFirstResponder()
        }
        
        if indexPath.section == 1 {
            let annotation = Annotation(text: "", timestamp: self.playerView.currentTime())
            cell.annotation = annotation
            cell.annotationTextView.becomeFirstResponder()
            displayThumbnail(forCell: cell)
        } else if indexPath.section == 0 {
            highlightedRow = indexPath.row
            currentAnnotationCell = cell
            UIView.animate(withDuration: 1, animations: {
                cell.backgroundColor = UIColor.rrk_highlightColor
                cell.backgroundColor = UIColor.rrk_primaryColorSelected
            })
            if !isEditMode {
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
            if let timestamp = cell.annotation?.timestamp {
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
        self.playerView.playVideo()
        //Edit annotation
        if !annotationCell.isNew {
            return
        }
        if annotations.count == 0 || newAnnotation.timestamp > annotations.last!.timestamp {
            // insert at end if no annotations, or the new annotation has the largest timestamp
            annotations.append(newAnnotation)
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            for (index, annotation) in annotations.enumerated() {
                if newAnnotation.timestamp < annotation.timestamp {
                    annotations.insert(newAnnotation, at: index)
                    break
                }
            }
        }
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
    
    func annotationCellNeedsLayoutUpdate(annotationCell: AnnotationCell) {
        // http://stackoverflow.com/questions/31595524/resize-uitableviewcell-containing-uitextview-upon-typing
        UIView.setAnimationsEnabled(false)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}

extension JoompedViewController: ASFSharedViewTransitionDataSource {
    func sharedView() -> UIView! {
        return playerView
    }
}

extension JoompedViewController: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        guard let videoId = joomped?.video.youtubeId ?? self.youtubeVideo?.id else {
            return
        }
        
        duration = Float(playerView.duration())
        
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
        if let annotation = annotationsDict[floor(playTime)] {
            if annotation != currentAnnotation && timer.isValid {
                timer.invalidate()
            }
            
            liveAnnotationLabel?.text = annotation.text
            currentAnnotation = annotation
            if let index = annotations.index(of: annotation) {
                let indexPath = IndexPath(row: index, section: 0)
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                let currentCell = tableView.cellForRow(at: indexPath) as? AnnotationCell
                highlightedRow = indexPath.row
                if currentCell?.backgroundColor != UIColor.rrk_highlightColor {
                    UIView.animate(withDuration: 1, animations: {
                        currentCell?.backgroundColor = UIColor.rrk_highlightColor
                    })
                }
                self.currentAnnotationCell = currentCell
                unhighlightVisbileCells()
            }
            
            timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(setAnnotationLabel), userInfo: nil, repeats: false)
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
