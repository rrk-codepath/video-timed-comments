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

class CreationViewController: UIViewController {

    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var annotationTextField: UITextField!
    @IBOutlet weak var timestampLabel: UILabel!
    let videoId = "M7lc1UVf-VE"
    var annotations = [Annotation]()
    var annotationTime: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let playerVars = ["playsinline": 1]
        playerView.load(withVideoId: videoId, playerVars: playerVars)
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
    
    @IBAction func editingDidBeginTextField(_ sender: Any) {
        print("editing did begin")
    }
    
    @IBAction func touchDownTextField(_ sender: Any) {
        print("touch down")
        // TODO: add formatting for time into hours, minutes, seconds in video
        annotationTime = playerView.currentTime()
        if let annotationTime = annotationTime {
            timestampLabel.text = String(annotationTime)
        }
    }
    
    
    @IBAction func didTapAnnotationSave(_ sender: Any) {
        print("did tap annotation save")
        let annotation = Annotation()
        guard let annotationText = annotationTextField.text, !annotationText.isEmpty else {
            return
        }
        annotation.text = annotationText
        if let annotationTime = annotationTime {
            annotation.timestamp = annotationTime
        }
        // TODO: insert in sorted order
        annotations.append(annotation)
        
        // reset state
        annotationTextField.text = ""
        
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
