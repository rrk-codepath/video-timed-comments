//
//  Date+Relative.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/16/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation

extension Date {
    // Adapted from https://github.com/kevinlawler/NSDate-TimeAgo/blob/master/NSDate%2BExtension.swift#L76
    public var timeAgoSimple: String {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .month, .year], from: self as Date, to: Date())
        if components.year! > 0 {
            return "\(components.year!)yr"
        }
        
        if components.month! > 0 {
            return "\(components.month!)w"
        }
        
        // TODO: localize for other calanders
        if components.day! >= 7 {
            let value = components.day!/7
            return "\(value)w"
        }
        
        if components.day! > 0 {
            return "\(components.day!)d"
        }
        
        if components.hour! > 0 {
            return "\(components.hour!)h"
        }
        
        if components.minute! > 0 {
            return "\(components.minute!)m"
        }
        
        if components.second! > 0 {
            return "\(components.second!)s"
        }
        return ""
    }
    
    public var timeFormatted: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy, h:mma"
        dateFormatter.timeZone = TimeZone.current
        let timeStamp = dateFormatter.string(from: self)
        
        return timeStamp
    }
    
    public var timeAgoRelative: String {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .month, .year], from: self as Date, to: Date())
        
        if components.year! > 0 {
            if components.year! < 2 {
                return "Last year"
            } else {
                return "\(components.year!) years ago"
            }
        }
        
        if components.month! > 0 {
            if components.month! < 2 {
                return "Last month"
            } else {
                return "\(components.month!) months ago"
            }
        }
        
        if components.day! >= 7 {
            let week = components.day!/7
            if week < 2 {
                return "Last week"
            } else {
                return "\(week) weeks ago"
            }
        }
        
        if components.day! > 0 {
            if components.day! < 2 {
                return "Yesterday"
            } else  {
                return "\(components.day!) days ago"
            }
        }
        
        if components.hour! > 0 {
            if components.hour! < 2 {
                return "An hour ago"
            } else  {
                return "\(components.hour!) hours ago"
            }
        }
        
        if components.minute! > 0 {
            if components.minute! < 2 {
                return "A minute ago"
            } else {
                return "\(components.minute!) minutes ago"
            }
        }
        
        if components.second! > 0 {
            if components.second! < 5 {
                return "Just now"
            } else {
                return "\(components.second!) seconds ago"
            }
        }
        
        return ""
    }
}
