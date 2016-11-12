import UIKit
import AFNetworking

class JoompedTableViewCell: UITableViewCell {

    @IBOutlet weak var joompedTitleLabel: UILabel!
    @IBOutlet weak var videoAuthorLabel: UILabel!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var joompedAuthorLabel: UILabel!
    
    var joomped: Joomped? {
        didSet {
            guard let joomped = joomped else {
                // Should reset
                return
            }
            
            joompedAuthorLabel.text = joomped.user.username
            joompedTitleLabel.text = joomped.video.title
            videoAuthorLabel.text = joomped.video.author
            if let thumbnail = joomped.video.thumbnail, let thumbnailUrl = URL(string: thumbnail) {
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
