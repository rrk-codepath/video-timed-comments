import Foundation

final class YoutubeThumbnail {
    
    static let empty = YoutubeThumbnail(url: "", width: 0, height: 0)
    
    let url: String
    let width: Int
    let height: Int
    
    init(url: String, width: Int, height: Int) {
        self.url = url
        self.width = width
        self.height = height
    }
}
