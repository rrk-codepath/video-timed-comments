import Foundation

/**
 * "uploadStatus": string,
 * "failureReason": string,
 * "rejectionReason": string,
 * "privacyStatus": string,
 * "publishAt": datetime,
 * "license": string,
 * "embeddable": boolean,
 * "publicStatsViewable": boolean
 */
final class YoutubeStatus {
    
    static let empty = YoutubeStatus(embeddable: true)
    let embeddable: Bool
    
    init(embeddable: Bool) {
        self.embeddable = embeddable
    }
}
