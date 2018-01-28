import Foundation
import AFNetworking
import GoogleSignIn

final class Youtube {
    
    private static let baseUrl = "https://www.googleapis.com/youtube/v3"
    private static let key = "AIzaSyANijfbKhKbuIqqt7cJy6zbwE4ewsHIdQg"

    private var authToken: String? {
        return GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken
    }
    
    var authenticated: Bool {
        return authToken != nil
    }
    
    func videoIds(videoIds: [String], success: @escaping (([YoutubeVideo]) -> Void), failure: ((Error) -> Void)?) {
        let videoIdsString = videoIds.joined(separator: ",")
        request(
            path: "videos",
            parameters: [
                "part": "id,snippet,statistics,contentDetails" as AnyObject,
                "id": videoIdsString as AnyObject
            ],
            success: { (dictionary: Dictionary<String, AnyObject>) -> Void in
                self.onReceivedVideos(dictionary: dictionary, success: success, failure: failure)
            },
            failure: failure
        )
    }
    
    func liked(success: @escaping (([YoutubeVideo]) -> Void), failure: ((Error) -> Void)?) {
        userRequest(
            path: "videos",
            parameters: [
                "part": "id,snippet,status,contentDetails" as AnyObject,
                "myRating": "like" as AnyObject,
                "maxResults": 50 as AnyObject
            ],
            success: { (dictionary: Dictionary<String, AnyObject>) -> Void in
                self.onReceivedVideos(dictionary: dictionary, success: success, failure: failure)
            },
            failure: failure
        )
    }
    
    func popular(success: @escaping (([YoutubeVideo]) -> Void), failure: ((Error) -> Void)?) {
        request(
            path: "videos",
            parameters: [
                "part": "id,snippet" as AnyObject,
                "chart": "mostPopular" as AnyObject,
                "regionCode": "US" as AnyObject,
                "videoCategoryId": 28 as AnyObject, // Hardcoded science
                "maxResults": 50 as AnyObject
            ],
            success: { (dictionary: Dictionary<String, AnyObject>) -> Void in
                self.onReceivedVideos(dictionary: dictionary, success: success, failure: failure)
            },
            failure: failure
        )
    }
    
    private func onReceivedVideos(dictionary: Dictionary<String, AnyObject>, success: @escaping (([YoutubeVideo]) -> Void), failure: ((Error) -> Void)?) {
        guard let items = dictionary["items"] as? [Dictionary<String, AnyObject>] else {
            failure?(YoutubeError.failed)
            return
        }
        
        let videos = items.map({ (d: Dictionary<String, AnyObject>) -> YoutubeVideo in
            return YoutubeVideo(dictionary: d)
        })
        
        success(videos)
    }
    
    func search(term: String, success: @escaping (([YoutubeVideo]) -> Void), failure: ((Error) -> Void)?) {
        request(
            path: "search",
            parameters: [
                "type": "video" as AnyObject,
                "part": "id,snippet" as AnyObject,
                "q": term as AnyObject,
                "maxResults": 50 as AnyObject
            ],
            success: { (dictionary: Dictionary<String, AnyObject>) -> Void in
                guard let items = dictionary["items"] as? [Dictionary<String, AnyObject>] else {
                    failure?(YoutubeError.failed)
                    return
                }
                
                let videoIds = items.map({ (d: Dictionary<String, AnyObject>) -> String in
                    return YoutubeVideo(dictionary: d).id
                })
                
                self.videoIds(videoIds: videoIds, success: success, failure: failure)
            },
            failure: failure
        )
    }

    
    private func userRequest(path: String, parameters: Dictionary<String, AnyObject>, success: @escaping ((Dictionary<String, AnyObject>) -> Void), failure: ((Error) -> Void)?) {
        guard authToken != nil else {
            failure?(YoutubeError.unauthorized)
            return
        }
        
        request(path: path, parameters: parameters, success: success, failure: failure)
    }
    
    private func request(path: String, parameters: Dictionary<String, AnyObject>, success: @escaping ((Dictionary<String, AnyObject>) -> Void), failure: ((Error) -> Void)?) {
        var parametersWithKey: Dictionary<String, AnyObject> = [:]
        parametersWithKey["key"] = Youtube.key as AnyObject
        for (key, value) in parameters {
            parametersWithKey[key] = value
        }

        let sessionManager = AFHTTPSessionManager(sessionConfiguration: URLSessionConfiguration.default)
        sessionManager.requestSerializer = AFHTTPRequestSerializer()
        if let authToken = authToken {
            sessionManager.requestSerializer.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        let taskOrNil = sessionManager.get(
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
                if let response = task?.response as? HTTPURLResponse,
                    response.statusCode == 401 {
                    failure?(YoutubeError.unauthorized)
                } else {
                    failure?(error)
                }
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
        let videoId = (d["id"]?["videoId"] ?? d["id"]) as? String ?? ""
        var snippet = YoutubeSnippet.empty
        if let snippetDictionary = d["snippet"] as? Dictionary<String, AnyObject> {
            snippet = YoutubeSnippet(dictionary: snippetDictionary)
        }
        var statistics = YoutubeStatistics.empty
        if let statisticsDictionary = d["statistics"] as? Dictionary<String, AnyObject> {
            statistics = YoutubeStatistics(dictionary: statisticsDictionary)
        }
        var status = YoutubeStatus.empty
        if let statusDictionary = d["status"] as? Dictionary<String, AnyObject> {
            status = YoutubeStatus(dictionary: statusDictionary)
        }
        var details: YoutubeVideoDetails? = nil
        if let detailsDict = d["contentDetails"] as? Dictionary<String, AnyObject> {
            details = YoutubeVideoDetails(dictionary: detailsDict)
        }
        
        self.init(id: videoId, snippet: snippet, statistics: statistics, status: status, details: details)
    }
}

extension YoutubeStatistics {
    convenience init(dictionary d: Dictionary<String, AnyObject>) {
        let viewCount = Int(d["viewCount"] as? String ?? "0") ?? 0
        let likeCount = Int(d["likeCount"] as? String ?? "0") ?? 0
        let dislikeCount = Int(d["dislikeCount"] as? String ?? "0") ?? 0
        let favoriteCount = Int(d["favoriteCount"] as? String ?? "0") ?? 0
        let commentCount = Int(d["commentCount"] as? String ?? "0") ?? 0
        self.init(viewCount: viewCount, likeCount: likeCount, dislikeCount: dislikeCount, favoriteCount: favoriteCount, commentCount: commentCount)
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

extension YoutubeStatus {
    
    convenience init(dictionary d: Dictionary<String, AnyObject>) {
        let embeddable = d["embeddable"] as? Bool ?? false
        self.init(embeddable: embeddable)
    }
}

extension YoutubeVideoDetails {
    
    convenience init(dictionary d: Dictionary<String, AnyObject>) {
        var duration: TimeInterval = 0
        if let durationString = d["duration"] as? String {
            let parts = Array(durationString.split(byRegex: "PT|H|M|S|DT")
                .map({(component: String) -> Int? in
                    return Int(component)
                })
                .filter({(component: Int?) -> Bool in component != nil})
                .map({(component: Int?) -> Int in component!})
                .reversed())
            
            var totalSeconds = 0
            let length = parts.count
            for i in 0...length - 1 {
                switch i {
                case 0:
                    totalSeconds += parts[i]
                case 1:
                    totalSeconds += parts[i] * 60
                case 2:
                    totalSeconds += parts[i] * 3600
                case 3:
                    totalSeconds += parts[i] * 86400
                default:
                    continue
                }
            }
            duration = TimeInterval(totalSeconds)
        }
        
        let dimension = d["dimension"] as? String ?? ""
        let definition = d["definition"] as? String ?? ""
        self.init(duration: duration, definition: definition, dimension: dimension)
    }
}

fileprivate extension String {
    
    func split(byRegex regex: String) -> [String] {
        let regEx = try! NSRegularExpression(pattern: regex, options: NSRegularExpression.Options())
        let stop = "|||||"
        let modifiedString = regEx.stringByReplacingMatches(
            in: self, options: NSRegularExpression.MatchingOptions(),
            range: NSMakeRange(0, self.count),
            withTemplate:stop
        )
        return modifiedString.components(separatedBy: stop)
    }
}

enum YoutubeError: Error {
    case failed
    case unauthorized
}
