import UIKit

extension UIImageView {
    
    func setImageWith(_ url: URL, fadeTime: TimeInterval) {
        let request = URLRequest(url: url)
        
        setImageWith(request, placeholderImage: nil, success: { (request: URLRequest, response: HTTPURLResponse?, image: UIImage) -> Void in
            self.alpha = 0
            self.image = image
            UIView.animate(withDuration: fadeTime, animations: {
                self.alpha = 1
            })
        }, failure: nil)
    }
}
