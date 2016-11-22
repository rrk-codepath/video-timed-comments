import Foundation

final class YoutubeVideo {
    
    let id: String
    let snippet: YoutubeSnippet
    let statistics: YoutubeStatistics
    let status: YoutubeStatus
    
    init(id: String, snippet: YoutubeSnippet, statistics: YoutubeStatistics, status: YoutubeStatus) {
        self.id = id
        self.snippet = snippet
        self.statistics = statistics
        self.status = status
    }
}
