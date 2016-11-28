import Foundation
import Parse

final class User: PFUser {
    
    var displayName: String? {
        get {
            return super["displayName"] as? String
        }
        set {
            super["displayName"] = newValue
        }
    }
    
    var imageUrl: String {
        get {
            return super["imageUrl"] as? String ?? "https://placekitten.com/g/100/100"
        }
        set {
            super["imageUrl"] = newValue
        }
    }
}
