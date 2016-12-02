//
//  ParseUtility.swift
//  Joomped
//
//  Created by Rahul Pandey on 12/1/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation
import Parse

class ParseUtility {
    
    // This hack is necessary since making the array contains call on parse objects fails
    static func contains(objects: [PFObject], element: PFObject) -> Bool {
        for object in objects {
            if object.objectId == element.objectId {
                return true
            }
        }
        return false
    }
    
    static func indexOf(objects: [PFObject], element: PFObject) -> Int {
        for (index, object) in objects.enumerated() {
            if object.objectId == element.objectId {
                return index
            }
        }
        return -1
    }
}
