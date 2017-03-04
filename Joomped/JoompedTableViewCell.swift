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
            
            self.joompedTitleLabel.text = joomped.video.title
            self.videoAuthorLabel.text = joomped.video.author
            self.videoLengthLabel.text = Float(joomped.video.length).joompedBeautify()
            let notes = joomped.annotations.count == 1 ? "note" : "notes"
            self.annotationCountLabel.text = "\(joomped.annotations.count) \(notes)"
            let views = joomped.views == 1 ? "view" : "views"
            self.viewCountLabel.text = "\(joomped.views) \(views)"
            if let name = joomped.user.name {
                self.joompedAuthorLabel.text = "\(name)"
            }
            
            if oldValue?.video.thumbnail != joomped.video.thumbnail {
                self.videoImageView.image = nil
                if let thumbnail = joomped.video.thumbnail, let thumbnailUrl = URL(string: thumbnail) {
                    self.videoImageView.setImageWith(thumbnailUrl, fadeTime: 0.2)
                }
            }
            
            self.timestampLabel.text = joomped.createdAt?.timeAgoRelative
            if self.timestampLabel.text != nil && self.timestampLabel.text!.isEmpty {
                // Timestamp is sometimes nil for newly created videos, so we get empty string
                self.timestampLabel.text = "Just now"
            }
            if let imageUrl = joomped.user.imageUrl,
                let url = URL(string: imageUrl) {
                self.joompedAuthorImageView.setImageWith(url, placeholderImage: #imageLiteral(resourceName: "Person"))
            } else {
                self.joompedAuthorImageView.image = #imageLiteral(resourceName: "Person")
            }

            if let name = joomped.user.name {
                self.joompedAuthorLabel.text = "\(name)"
            }
            
            if let imageUrl = joomped.user.imageUrl,
                let url = URL(string: imageUrl) {
                self.joompedAuthorImageView.setImageWith(url, placeholderImage: #imageLiteral(resourceName: "Person"))
            } else {
                self.joompedAuthorImageView.image = #imageLiteral(resourceName: "Person")
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
