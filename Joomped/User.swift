import Foundation
import Parse

final class User: PFUser {
    
    var name: String? {
        guard let firstName = super["firstName"] as? String, let lastName = super["lastName"] as? String else {
            return ""
        }
        return "\(firstName) \(lastName)"
    }
    
    var firstName: String? {
        get {
            return super["firstName"] as? String
        }
        set {
            super["firstName"] = newValue
        }
    }
    
    var lastName: String? {
        get {
            return super["lastName"] as? String
        }
        set {
            super["lastName"] = newValue
        }
    }

    var imageUrl: String? {
        get {
            return super["imageUrl"] as? String
        }
        set {
            super["imageUrl"] = newValue
        }
    }
    
    var gaveKarma: [Joomped] {
        get {
            return super["gaveKarma"] as? [Joomped] ?? []
        }
        set {
            super["gaveKarma"] = newValue
        }
    }
}
