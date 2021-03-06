//
//  AnnotationCell.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/11/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit

@objc protocol AnnotationCellDelegate: class {
    @objc optional func annotationCell(annotationCell: AnnotationCell, addedAnnotation newAnnotation: Annotation)
    @objc optional func annotationCell(annotationCell: AnnotationCell, removedAnnotation: Annotation)
    @objc optional func annotationCell(annotationCell: AnnotationCell, tappedTimestamp timestamp: Float)
    @objc optional func annotationCellNeedsLayoutUpdate(annotationCell: AnnotationCell)
}

class AnnotationCell: UITableViewCell {
    @IBOutlet weak var thumbnailWidth: NSLayoutConstraint!
    @IBOutlet weak var annotationTextView: UITextView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var annotationLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    weak var delegate: AnnotationCellDelegate?
    var isNew: Bool = false


    var timestampFloat: Float?
    
    var isEditMode: Bool = false {
        didSet {
            annotationLabel.isHidden = isEditMode
            annotationTextView.isHidden = !isEditMode
            saveButton.isHidden = !isEditMode
            if isEditMode {
                annotationTextView.textColor = UIColor.darkGray
            }
        }
    }
    
    var annotation: Annotation? {
        didSet {
            if let annotation = annotation {
                annotationTextView.text = annotation.text
                annotationLabel.text = annotation.text
                timestampFloat = annotation.timestamp
                timestampLabel.text = annotation.timestamp.joompedBeautify()
                timestampLabel.isHidden = false
            } else {
                annotationTextView.text = "Add a thought..."
                annotationTextView.textColor = UIColor.lightGray
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        annotationTextView.delegate = self
        let padding = annotationTextView.textContainer.lineFragmentPadding
        annotationTextView.textContainerInset = UIEdgeInsetsMake(-0.5, -padding, 0, -padding)
        thumbnailImageView.alpha = 0.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func didTapSaveButton(_ sender: Any) {
        saveAnnotation()
    }
    
    func hideThumbnail() {
    }
    
    func showThumbnail() {
        UIView.animate(withDuration: 0.2, animations: {
            self.thumbnailImageView.alpha = 0.5
        })
    }
    
    fileprivate func saveAnnotation() {
        guard let annotation = annotation, let annotationText = annotationTextView.text, !annotationText.isEmpty else {
            annotationTextView.layer.borderColor = UIColor.red.cgColor
            annotationTextView.layer.borderWidth = 1.0
            return
        }
        annotationTextView.layer.borderWidth = 0
        annotationTextView.resignFirstResponder()
        
        annotation.text = annotationTextView.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        annotation.timestamp = timestampFloat!
        self.saveButton.isEnabled = false
        
        delegate?.annotationCell?(annotationCell: self, addedAnnotation: annotation)
    }
}

extension AnnotationCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        saveButton.isEnabled = annotationTextView.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count > 0
        
        // http://stackoverflow.com/questions/31595524/resize-uitableviewcell-containing-uitextview-upon-typing
        let startHeight = textView.frame.size.height
        let calcHeight = textView.sizeThatFits(textView.frame.size).height  //iOS 8+ only
        if startHeight != calcHeight {
            delegate?.annotationCellNeedsLayoutUpdate?(annotationCell: self)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = UIColor.darkGray
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add a thought.."
            textView.textColor = UIColor.lightGray
        }
    }
}
