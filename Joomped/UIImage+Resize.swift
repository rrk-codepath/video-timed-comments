import UIKit

extension UIImage {
    
    // http://stackoverflow.com/questions/31966885/ios-swift-resize-image-to-200x200pt-px
    func scaleImage(toSize newSize: CGSize) -> UIImage {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context: CGContext! = UIGraphicsGetCurrentContext()
        context.interpolationQuality = .high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context.concatenate(flipVertical)
        context.draw(cgImage!, in: newRect)
        let newImage = UIImage(cgImage: context.makeImage()!)
        UIGraphicsEndImageContext()
        return newImage
    }
}
