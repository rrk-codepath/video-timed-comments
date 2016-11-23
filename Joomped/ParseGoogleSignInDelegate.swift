import Foundation
import GoogleSignIn
import Parse

protocol ParseLoginDelegate: class {
    
    func login(didSucceedFor user: PFUser)
    
    func login(didFailWith error: Error?)
}

final class ParseGoogleSignInDelegate: NSObject, GIDSignInDelegate {
    
    // TODO: Find a way around parse requiring an explicit password
    private static let password = ""
    
    weak var delegate: ParseLoginDelegate?
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            delegate?.login(didFailWith: error)
            return
        }
        
        findCredentials(
            withId: user.userID,
            success: { (creds: GoogleCredentials) -> Void in
                self.updateGoogleCredentials(user: user, credentials: creds, success: nil, failure: nil)
                creds.user.fetchIfNeededInBackground(block: { (object: PFObject?, error: Error?) in
                    guard let parseUser = object as? User,
                        let username = parseUser.username else {
                        self.delegate?.login(didFailWith: error ?? LoginError.unknown)
                        return
                    }
                    
                    PFUser.logInWithUsername(inBackground: username, password: ParseGoogleSignInDelegate.password, block: { (parseUser: PFUser?, error: Error?) in
                        guard let parseUser = parseUser as? User else {
                            self.delegate?.login(didFailWith: error ?? LoginError.unknown)
                            return
                        }
                        
                        self.updateParseUser(user: parseUser, gidUser: user)
                        
                        self.delegate?.login(didSucceedFor: parseUser)
                    })
                })
            },
            failure: { () -> Void in
                // Create credentials
                let creds = GoogleCredentials()
                let newUser = User()
                
                // TODO: Use an actual hash here
                newUser.username = String("\(Date().timeIntervalSince1970)\(user.userID!)").data(using: String.Encoding.utf8)?.base64EncodedString(options: [])
                newUser.password = ParseGoogleSignInDelegate.password
                newUser.displayName = self.displayName(fromEmail: user.profile.email)
                newUser.imageUrl = user.profile.imageURL(withDimension: 100).absoluteString
                newUser.signUpInBackground(block: { (success: Bool, error: Error?) in
                    creds.user = newUser
                    newUser.saveInBackground()
                    
                    self.updateGoogleCredentials(user: user, credentials: creds,
                        success: { () -> Void in
                            self.delegate?.login(didSucceedFor: newUser)
                        },
                        failure: { (error: Error?) -> Void in
                            self.delegate?.login(didFailWith: error ?? LoginError.unknown)
                        }
                    )
                })
            }
        )
    }
    
    private func updateParseUser(user: User, gidUser:
        GIDGoogleUser) {
        let url = gidUser.profile.imageURL(withDimension: 100).absoluteString
        user.imageUrl = url
        user.saveInBackground()
    }
    
    private func updateGoogleCredentials(user: GIDGoogleUser, credentials creds: GoogleCredentials, success: (() -> Void)?, failure: ((Error?) -> Void)?) {
        creds.userId = user.userID
        creds.authToken = user.authentication.accessToken
        creds.fullName = user.profile.name
        creds.givenName = user.profile.givenName
        creds.familyName = user.profile.familyName
        creds.email = user.profile.email
        creds.saveInBackground { (successful: Bool, error: Error?) in
            if successful {
                success?()
            } else {
                failure?(error)
            }
        }
    }
    
    private func findCredentials(withId userId: String, success: @escaping (GoogleCredentials) -> Void, failure: @escaping () -> Void) {
        let query = PFQuery(className:"GoogleCredentials")
        query.whereKey("userId", equalTo: userId)
        query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            guard let creds = objects as? [GoogleCredentials], creds.count > 0 else {
                failure()
                return
            }
            
            success(creds[0])
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
    
    private func displayName(fromEmail email: String) -> String {
        if let range = email.range(of: "@") {
            return email.substring(to: range.lowerBound)
        }
        
        return email
    }
}

enum LoginError: Error {
    case unknown
}
