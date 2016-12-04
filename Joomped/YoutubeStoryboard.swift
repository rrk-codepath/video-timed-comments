import AFNetworking
import Foundation

final class YoutubeStoryboard {
    
    var rows: Int = 0
    var columns: Int = 0
    
    private let videoId: String
    private var storyboardUrls: [URL] = []
    private var thumbnails: Int = 0
    private var thumbnailsPerSheet: Int = 0
    private var fetching: Bool = true
    private var failed: Bool = false
    private var callbacks: [Callback] = []
    
    init(videoId: String) {
        self.videoId = videoId
        fetchStoryboardUrls()
    }
    
    func getThumbnail(progress: Float, callback: @escaping (URL, Location) -> Void, failure: @escaping () -> Void) -> Void {
        if fetching {
            callbacks.append(Callback(callback: callback, failure: failure, progress: progress))
            return
        }
        
        if failed {
            failure()
            return
        }
        
        getThumbnailInternal(progress: progress, callback: callback)
    }
    
    private func getThumbnailInternal(progress: Float, callback: (URL, Location) -> Void) {
        guard storyboardUrls.count > 0, rows > 0, columns > 0, thumbnails > 0 else {
            return
        }
        let thumbnailsPerSheet = rows * columns
        let sheet = Int(floor(Double(progress) * Double(thumbnails) / Double(thumbnailsPerSheet)))
        let thumbnail = Int(floor(Double(progress) * Double(thumbnails)))
        let remainder = thumbnail - sheet * thumbnailsPerSheet
        let row = Int(floor(Double(remainder) / Double(columns)))
        let column = remainder % rows
        let location = Location(row: row, column: column)
        let urlIndex = min(sheet, storyboardUrls.count - 1)
        callback(storyboardUrls[urlIndex], location)
    }
    
    // Thank god for stack overflow
    // http://stackoverflow.com/questions/34506615/how-can-i-get-youtube-video-story-board-from-get-video-info-url-in-php-json
    private func fetchStoryboardUrls() -> Void {
        guard let url = URL(string: "https://www.youtube.com/get_video_info?video_id=\(videoId)&el=detailpage") else {
            return
        }
        let manager = AFURLSessionManager(sessionConfiguration: URLSessionConfiguration.default)
        let responseSerializer =  AFHTTPResponseSerializer()
        responseSerializer.acceptableContentTypes = Set(arrayLiteral: "application/x-www-form-urlencoded")
        manager.responseSerializer = responseSerializer
        
        let request = URLRequest(url: url)
        let task = manager.dataTask(with: request, completionHandler: { (response: URLResponse, payload: Any?, error: Error?) -> Void in
            guard let data = payload as? Data,
                let decoded = String(data: data, encoding: String.Encoding.ascii) else {
                self.onFailure()
                return
            }
            print("storyboard index=\(decoded.range(of: "storyboard_spec")?.lowerBound)")
            let videoInfo = self.getKeyVals(query: decoded)
            
            guard let spec = videoInfo["storyboard_spec"] else {
                self.onFailure()
                return
            }
            
            let specParts = spec.components(separatedBy: "|")
            guard specParts.count >= 4 else {
                self.onFailure()
                return
            }
            
            let urlParts = specParts[0].components(separatedBy: "$")
            guard urlParts.count > 0 else {
                self.onFailure()
                return
            }
            
            let baseUrl = "\(urlParts[0])2/M"
            let sigParts = specParts[3].components(separatedBy: "#")
            
            guard let signature = sigParts.last,
                let thumbnails = Int(sigParts[2]),
                let rows = Int(sigParts[3]),
                let columns = Int(sigParts[4]) else {
                self.onFailure()
                return
            }
            
            let sheets = Int(ceil(Double(thumbnails) / Double(rows * columns)))
            
            var urls: [URL] = []
            
            for i in 0...sheets - 1 {
                if let url = URL(string: "\(baseUrl)\(i).jpg?sigh=\(signature)") {
                    urls.append(url)
                }
            }
            
            self.storyboardUrls = urls
            self.thumbnails = thumbnails
            self.rows = rows
            self.columns = columns
            
            while self.callbacks.count > 0 {
                guard let cb = self.callbacks.popLast() else {
                    break
                }
                self.getThumbnailInternal(progress: cb.progress, callback: cb.callback)
            }
            
            self.fetching = false
        })
        
        task.resume()
    }
    
    private func getKeyVals(query: String) -> Dictionary<String, String> {
        var results = [String:String]()
        guard let keyValues = query.removingPercentEncoding?.components(separatedBy: "&") else {
            return results
        }
        
        if keyValues.count > 0 {
            for pair in keyValues {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1,
                    let key = kv[0].removingPercentEncoding,
                    let value = kv[1].removingPercentEncoding {
                    results[key] = value
                }
            }
        }
        return results
    }
    
    private func onFailure() {
        fetching = false
        failed = true
        while self.callbacks.count > 0 {
            guard let cb = self.callbacks.popLast() else {
                break
            }
            cb.failure()
        }
    }
    
    private class Callback {
        let callback: (URL, Location) -> Void
        let failure: () -> Void
        let progress: Float
        
        init(callback: @escaping (URL, Location) -> Void, failure: @escaping () -> Void, progress: Float) {
            self.progress = progress
            self.callback = callback
            self.failure = failure
        }
    }
    
    struct Location {
        
        let row: Int
        let column: Int
        
        init(row: Int, column: Int) {
            self.row = row
            self.column = column
        }
    }
}
