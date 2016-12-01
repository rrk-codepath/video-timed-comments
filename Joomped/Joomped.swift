import Parse

final class Joomped: PFObject, PFSubclassing {
    
    public static func parseClassName() -> String {
        return "Joomped"
    }
    
    var video: Video {
        get {
            return super["video"] as! Video
        }
        set {
            super["video"] = newValue
        }
    }
    
    var annotations: [Annotation] {
        get {
            return super["annotations"] as! [Annotation]
        }
        set {
            super["annotations"] = newValue
        }
    }
    
    var user: User {
        get {
            return super["user"] as! User
        }
        set {
            super["user"] = newValue
        }
    }
    
    var views: Int {
        get {
            return super["views"] as! Int
        }
        set {
            super["views"] = newValue
        }
    }
}
