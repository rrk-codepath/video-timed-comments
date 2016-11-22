import UIKit

final class YoutubeVideoTableViewCell: UITableViewCell {

    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var videoTitleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var youtubeVideo: YoutubeVideo? {
        didSet {
            guard let video = youtubeVideo else {
                return
            }
            
            videoTitleLabel.text = video.snippet.title
            authorLabel.text = video.snippet.channelTitle
            timestampLabel.text = video.snippet.publishedAt.timeAgoRelative
            if let thumbnailUrl = URL(string: video.snippet.thumbnail.url) {
                videoImageView.setImageWith(thumbnailUrl)
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
