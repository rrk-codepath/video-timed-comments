import Foundation

final class YoutubeSnippet {
    
    static let empty = YoutubeSnippet(publishedAt: Date.distantPast, channelId: "", title: "", description: "", thumbnail: YoutubeThumbnail.empty, channelTitle: "", liveBroadcastContent: "")
    
    let publishedAt: Date
    let channelId: String
    let title: String
    let description: String
    let thumbnail: YoutubeThumbnail
    let channelTitle: String
    let liveBroadcastContent: String
    
    init(publishedAt: Date, channelId: String, title: String, description: String, thumbnail: YoutubeThumbnail, channelTitle: String, liveBroadcastContent: String) {
        self.publishedAt = publishedAt
        self.channelId = channelId
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.channelTitle = channelTitle
        self.liveBroadcastContent = liveBroadcastContent
    }
}
