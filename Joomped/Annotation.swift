import Parse

final class Annotation: PFObject, PFSubclassing {
    
    public static func parseClassName() -> String {
        return "Annotation"
    }
    
    var timestamp: Float {
        get {
            return super["timestamp"] as! Float
        }
        set {
            super["timestamp"] = newValue
        }
    }
    
    var text: String {
        get {
            return super["text"] as! String
        }
        set {
            super["text"] = newValue
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
    
    var joomped: Joomped {
        get {
            return super["joomped"] as! Joomped
        }
        set {
            super["joomped"] = newValue
        }
    }
    
    init(text: String, timestamp: Float) {
        super.init()
        self.text = text
        self.timestamp = timestamp
    }
    
    override init() {
        super.init()
    }
}
