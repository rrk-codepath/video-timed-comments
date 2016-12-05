import UIKit

extension UILabel {
    
    func setTextWithTypeAnimation(typedText: String, characterInterval: TimeInterval = 0.25) {
        text = ""
        DispatchQueue.global(qos: .userInteractive).async {
            for character in typedText.characters {
                DispatchQueue.main.async {
                    self.text = self.text! + String(character)
                }
                Thread.sleep(forTimeInterval: characterInterval)
            }
        }
    }
}
