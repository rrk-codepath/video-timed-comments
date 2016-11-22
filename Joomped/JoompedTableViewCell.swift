import UIKit
import AFNetworking

class JoompedTableViewCell: UITableViewCell {

    @IBOutlet weak var joompedTitleLabel: UILabel!
    @IBOutlet weak var videoAuthorLabel: UILabel!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var joompedAuthorLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var joomped: Joomped? {
        didSet {
            guard let joomped = joomped else {
                // Should reset
                return
            }
            
            joompedTitleLabel.text = joomped.video.title
            videoAuthorLabel.text = joomped.video.author
            if let joompedUser = joomped.user.displayName {
                var countString = "\(joomped.annotations.count) annotations"
                if joomped.annotations.count == 1 {
                    countString = countString.substring(to: countString.index(before: countString.endIndex))
                }
                joompedAuthorLabel.text = "\(joompedUser) • \(countString)"
            }
            if let thumbnail = joomped.video.thumbnail, let thumbnailUrl = URL(string: thumbnail) {
                videoImageView.setImageWith(thumbnailUrl)
            }
            timestampLabel.text = joomped.updatedAt?.timeAgoRelative
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
