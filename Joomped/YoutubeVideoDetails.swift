import Foundation

final class YoutubeVideoDetails {

    static let empty = YoutubeVideoDetails(duration: 0, definition: "", dimension: "")
    
    let duration: TimeInterval
    let definition: String
    let dimension: String
    
    init(duration: TimeInterval, definition: String, dimension: String) {
        self.duration = duration
        self.definition = definition
        self.dimension = dimension
    }
}
