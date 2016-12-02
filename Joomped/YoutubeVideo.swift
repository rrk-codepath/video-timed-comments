import Foundation

final class YoutubeVideo {
    
    let id: String
    let snippet: YoutubeSnippet
    let statistics: YoutubeStatistics
    let status: YoutubeStatus
    let details: YoutubeVideoDetails?
    
    init(id: String, snippet: YoutubeSnippet, statistics: YoutubeStatistics, status: YoutubeStatus, details: YoutubeVideoDetails?) {
        self.id = id
        self.snippet = snippet
        self.statistics = statistics
        self.status = status
        self.details = details
    }
}
