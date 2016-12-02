import UIKit
import AFNetworking

class JoompedTableViewCell: UITableViewCell {

    @IBOutlet weak var joompedTitleLabel: UILabel!
    @IBOutlet weak var videoAuthorLabel: UILabel!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var joompedAuthorLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var joompedAuthorImageView: UIImageView!
    @IBOutlet weak var videoLengthLabel: UILabel!
    @IBOutlet weak var annotationCountLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    var joomped: Joomped? {
        didSet {
            guard let joomped = joomped else {
                // Should reset
                return
            }
            
            joompedTitleLabel.text = joomped.video.title
            videoAuthorLabel.text = joomped.video.author
            videoLengthLabel.text = Float(joomped.video.length).joompedBeautify()
            let jumps = joomped.annotations.count == 1 ? "jump" : "jumps"
            annotationCountLabel.text = "\(joomped.annotations.count) \(jumps)"
            let views = joomped.views == 1 ? "view" : "views"
            viewCountLabel.text = "\(joomped.views) \(views)"
            if let joompedUser = joomped.user.displayName {
                joompedAuthorLabel.text = "\(joompedUser)"
            }
            if let thumbnail = joomped.video.thumbnail, let thumbnailUrl = URL(string: thumbnail) {
                videoImageView.setImageWith(thumbnailUrl)
            }
            timestampLabel.text = joomped.createdAt?.timeAgoRelative
            if let url = URL(string: joomped.user.imageUrl) {
                joompedAuthorImageView.setImageWith(url)
                joompedAuthorImageView.layer.cornerRadius = joompedAuthorImageView.frame.size.height / 2;
                joompedAuthorImageView.layer.masksToBounds = true;
                joompedAuthorImageView.layer.borderWidth = 0;
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
