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

class CreationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AnnotationCellDelegate {

    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var tableView: UITableView!
    
    let videoId = "M7lc1UVf-VE"
    var annotations = [Annotation]()
    var annotationTime: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let playerVars = ["playsinline": 1]
        playerView.load(withVideoId: videoId, playerVars: playerVars)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        tableView.register(UINib(nibName: "AnnotationCell", bundle: nil), forCellReuseIdentifier: "AnnotationCell")
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
    
    func annotationCell(annotationCell: AnnotationCell, addedAnnotation newAnnotation: Annotation) {
        // TODO: insert in sorted order
        annotations.append(newAnnotation)
        print("number of annotations now: \(annotations.count)")
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let numberOfSections = self.tableView.numberOfSections
            let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections - 1)
            let indexPath = IndexPath(item: numberOfRows - 1, section: numberOfSections - 1)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        print("did tap joomped save")
        guard let user = PFUser.current() as? User else {
            return
        }
        let joomped = Joomped()
        
        
        let video = Video()
        video.youtubeId = videoId
        video.length = playerView.duration()
        video.title = "Title of sample video"
        
        joomped.annotations = annotations
        joomped.user = user
        joomped.video = video
        joomped.saveInBackground { (success: Bool, error: Error?) in
            if let error = error {
                print("error saving \(error.localizedDescription)")
                return
            }
            print("saved successfully: \(joomped.objectId)")
        }
    }
    
    
//    @IBAction func touchDownTextField(_ sender: Any) {
//        // TODO: add formatting for time into hours, minutes, seconds in video
//        annotationTime = playerView.currentTime()
//        if let annotationTime = annotationTime {
//            timestampLabel.text = String(annotationTime)
//        }
//    }
    
//    @IBAction func didTapAnnotationSave(_ sender: Any) {
//        print("did tap annotation save")
//        let annotation = Annotation()
//        guard let annotationText = annotationTextField.text, !annotationText.isEmpty else {
//            return
//        }
//        annotation.text = annotationText
//        if let annotationTime = annotationTime {
//            annotation.timestamp = annotationTime
//        }
//        // TODO: insert in sorted order
//        annotations.append(annotation)
//        print("number of annotations now: \(annotations.count)")
//        // reset state
//        annotationTextField.text = ""
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
