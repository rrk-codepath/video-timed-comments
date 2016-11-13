import Foundation

final class YoutubeVideo {
    
    let id: String
    let snippet: YoutubeSnippet
    let statistics: YoutubeStatistics
    
    init(id: String, snippet: YoutubeSnippet, statistics: YoutubeStatistics) {
        self.id = id
        self.snippet = snippet
        self.statistics = statistics
    }
}
