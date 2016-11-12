import Foundation
import AFNetworking

final class Youtube {
    
    private static let baseUrl = "https://www.googleapis.com/youtube/v3"
    private static let key = "AIzaSyANijfbKhKbuIqqt7cJy6zbwE4ewsHIdQg"
    private static let requestSerializer = AFHTTPRequestSerializer()
    private static let sessionManager = AFHTTPSessionManager(sessionConfiguration: URLSessionConfiguration.default)
    
    func search(term: String, success: @escaping (([YoutubeVideo]) -> Void), failure: ((Error) -> Void)?) {
        request(
            path: "search",
            parameters: [
                "type": "video" as AnyObject,
                "part": "id,snippet" as AnyObject,
                "q": term as AnyObject
            ],
            success: { (dictionary: Dictionary<String, AnyObject>) -> Void in
                guard let items = dictionary["items"] as? [Dictionary<String, AnyObject>] else {
                        failure?(YoutubeError.failed)
                        return
                }
                
                let videos = items.map({ (d: Dictionary<String, AnyObject>) -> YoutubeVideo in
                    return YoutubeVideo(dictionary: d)
                })
                
                success(videos)
            },
            failure: failure
        )
    }
    
    private func request(path: String, parameters: Dictionary<String, AnyObject>, success: @escaping ((Dictionary<String, AnyObject>) -> Void), failure: ((Error) -> Void)?) {
        var parametersWithKey: Dictionary<String, AnyObject> = [:]
        parametersWithKey["key"] = Youtube.key as AnyObject
        for (key, value) in parameters {
            parametersWithKey[key] = value
        }
        
        let taskOrNil = Youtube.sessionManager.get(
            "\(Youtube.baseUrl)/\(path)",
            parameters: parametersWithKey,
            progress: nil,
            success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                guard let dictionary = responseObject as? Dictionary<String, AnyObject> else {
                    failure?(YoutubeError.failed)
                    return
                }
                
                success(dictionary)
            },
            failure: {(task: URLSessionDataTask?, error: Error) -> Void in
                failure?(error)
            }
        )
        
        guard let task = taskOrNil else {
            failure?(YoutubeError.failed)
            return
        }
        
        task.resume()
    }
}

extension YoutubeVideo {
    
    convenience init(dictionary d: Dictionary<String, AnyObject>) {
        let videoId = d["id"]?["videoId"] as? String ?? ""
        var snippet = YoutubeSnippet.empty
        if let snippetDictionary = d["snippet"] as? Dictionary<String, AnyObject> {
            snippet = YoutubeSnippet(dictionary: snippetDictionary)
        }
        
        self.init(id: videoId, snippet: snippet)
    }
}
extension YoutubeSnippet {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    convenience init(dictionary d: Dictionary<String, AnyObject>) {
        var publishedAt: Date = Date.distantPast
        if let publishedAtString = d["publishedAt"] as? String {
            publishedAt = YoutubeSnippet.iso8601.date(from: publishedAtString) ?? publishedAt
        }
        let channelId = d["channelId"] as? String ?? ""
        let title = d["title"] as? String ?? ""
        let description = d["description"] as? String ?? ""
        var thumbnail = YoutubeThumbnail.empty
        if let thumbnailDictionary = d["thumbnails"]?["default"] as? Dictionary<String, AnyObject> {
            thumbnail = YoutubeThumbnail(dictionary: thumbnailDictionary)
        }
        
        let channelTitle = d["channelTitle"] as? String ?? ""
        let liveBroadcastContent = d["liveBroadcastContent"] as? String ?? ""
        self.init(publishedAt: publishedAt, channelId: channelId, title: title, description: description, thumbnail: thumbnail, channelTitle: channelTitle, liveBroadcastContent: liveBroadcastContent)
    }
}

extension YoutubeThumbnail {
    
    convenience init(dictionary d: Dictionary<String, AnyObject>) {
        let url = d["url"] as? String ?? ""
        let width = d["width"] as? Int ?? 0
        let height = d["height"] as? Int ?? 0
        self.init(url: url, width: width, height: height)
    }
}

enum YoutubeError: Error {
    case failed
}
