import Foundation

final class YoutubeVideo {
    
    let id: String
    let snippet: YoutubeSnippet
    
    init(id: String, snippet: YoutubeSnippet) {
        self.id = id
        self.snippet = snippet
    }
}
