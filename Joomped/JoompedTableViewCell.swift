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
            
            if oldValue?.video.thumbnail != joomped.video.thumbnail {
                videoImageView.image = nil
                if let thumbnail = joomped.video.thumbnail, let thumbnailUrl = URL(string: thumbnail) {
                    videoImageView.setImageWith(thumbnailUrl, fadeTime: 0.2)
                }
            }
            
            timestampLabel.text = joomped.createdAt?.timeAgoRelative
            if timestampLabel.text != nil && timestampLabel.text!.isEmpty {
                // Timestamp is sometimes nil for newly created videos, so we get empty string
                timestampLabel.text = "Just now"
            }
            if let imageUrl = joomped.user.imageUrl,
                let url = URL(string: imageUrl) {
                joompedAuthorImageView.setImageWith(url, placeholderImage: #imageLiteral(resourceName: "Person"))
            } else {
                joompedAuthorImageView.image = #imageLiteral(resourceName: "Person")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        joompedAuthorImageView.layer.cornerRadius = joompedAuthorImageView.frame.size.height / 2;
        joompedAuthorImageView.layer.masksToBounds = true;
        joompedAuthorImageView.layer.borderWidth = 0;    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
