import Foundation

extension Float {
    
    func joompedBeautify() -> String {
        let interval = Int(self)
        let seconds = interval % 60
        let hours = interval / 3600
        let minutes = hours > 0 ? interval / 60 % 60 : interval / 60

        return hours > 0
            ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}
