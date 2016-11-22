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
}
