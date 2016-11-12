import UIKit

class JoomepdTableViewCell: UITableViewCell {

    @IBOutlet weak var joompedAuthorLabel: UILabel!
    @IBOutlet weak var videoAuthorLabel: UILabel!
    @IBOutlet weak var joompedTitle: UILabel!
    @IBOutlet weak var videoImageView: UIImageView!
    
    var joomped: Joomped? {
        didSet {
            guard let joomped = joomped else {
                // Should reset
                return
            }
            
            joompedAuthorLabel.text = joomped.user.username
            joompedTitle.text = joomped.video.title
            videoAuthorLabel.text = joomped.video.author
            if let thumbnailUrl = URL(string: joomped.video.thumbnail) {
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
