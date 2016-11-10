//
//  Video.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/9/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation
import Parse

class Video: PFObject, PFSubclassing {
    
    static let youtubeIdKey = "youtubeId"
    static let lengthKey = "length"
    static let titleKey = "title"
    
    public static func parseClassName() -> String {
        return "Video"
    }
    
    var youtubeId: String {
        get {
            return super[Video.youtubeIdKey] as! String
        }
        set {
            super[Video.youtubeIdKey] = newValue
        }
    }
    
    var length: TimeInterval {
        get {
            return super[Video.lengthKey] as! TimeInterval
        }
        set {
            super[Video.lengthKey] = newValue
        }
    }
    
    var title: String {
        get {
            return super[Video.titleKey] as! String
        }
        set {
            super[Video.titleKey] = newValue
        }
    }
    
}
