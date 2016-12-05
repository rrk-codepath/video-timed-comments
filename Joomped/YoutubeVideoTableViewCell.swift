import UIKit

final class YoutubeVideoTableViewCell: UITableViewCell {

    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var videoTitleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var videoLengthLabel: UILabel!
    
    var youtubeVideo: YoutubeVideo? {
        didSet {
            guard let video = youtubeVideo else {
                return
            }
            
            videoTitleLabel.text = video.snippet.title
            authorLabel.text = video.snippet.channelTitle
            timestampLabel.text = video.snippet.publishedAt.timeAgoRelative
            
            if oldValue?.snippet.thumbnail.url != video.snippet.thumbnail.url {
                videoImageView.image = nil
                if let thumbnailUrl = URL(string: video.snippet.thumbnail.url) {
                    videoImageView.setImageWith(thumbnailUrl, fadeTime: 0.2)
                }
            }
            
            if let details = video.details {
                videoLengthLabel.isHidden = false
                videoLengthLabel.text = Float(details.duration).joompedBeautify()
            } else {
                videoLengthLabel.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
