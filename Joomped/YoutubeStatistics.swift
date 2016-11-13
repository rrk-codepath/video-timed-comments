//
//  YoutubeStatistics.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/12/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import Foundation

// Currently unsused- this API call requires video ids; cannot be retrieved from a search query. see https://developers.google.com/apis-explorer/#p/youtube/v3/youtube.videos.list?part=snippet%252C+statistics&id=Ys7-6_t7OEQ&maxResults=50&_h=1&
final class YoutubeStatistics {
    
    static let empty = YoutubeStatistics(viewCount: -1, likeCount: -1, dislikeCount: -1, favoriteCount: -1, commentCount: -1)
    
    let viewCount: Int
    let likeCount: Int
    let dislikeCount: Int
    let favoriteCount: Int
    let commentCount: Int
    
    init(viewCount: Int, likeCount: Int, dislikeCount: Int, favoriteCount: Int, commentCount: Int) {
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.dislikeCount = dislikeCount
        self.favoriteCount = favoriteCount
        self.commentCount = commentCount
    }
}
