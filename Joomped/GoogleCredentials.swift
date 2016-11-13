import Parse

final class GoogleCredentials: PFObject, PFSubclassing {

    public static func parseClassName() -> String {
        return "GoogleCredentials"
    }
    
    var userId: String {
        get {
            return super["userId"] as! String
        }
        set {
            super["userId"] = newValue
        }
    }
    
    var authToken: String? {
        get {
            return super["authToken"] as? String
        }
        set {
            super["authToken"] = newValue
        }
    }
    
    var fullName: String? {
        get {
            return super["fullName"] as? String
        }
        set {
            super["fullName"] = newValue
        }
    }
    
    var givenName: String? {
        get {
            return super["givenName"] as? String
        }
        set {
            super["givenName"] = newValue
        }
    }
    
    var familyName: String? {
        get {
            return super["familyName"] as? String
        }
        set {
            super["familyName"] = newValue
        }
    }
    
    var email: String? {
        get {
            return super["email"] as? String
        }
        set {
            super["email"] = newValue
        }
    }
    
    var user: PFUser {
        get {
            return super["user"] as! PFUser
        }
        set {
            super["user"] = newValue
        }
    }
}
