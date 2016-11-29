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
}

class AnnotationCell: UITableViewCell {
    @IBOutlet weak var annotationTextView: UITextView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var annotationLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    weak var delegate: AnnotationCellDelegate?
    
    var timestampFloat: Float?
    
    var isEditMode: Bool = false {
        didSet {
            annotationLabel.isHidden = isEditMode
            annotationTextView.isHidden = !isEditMode
            saveButton.isHidden = !isEditMode
            closeButton.isHidden = !isEditMode
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
                annotationTextView.isUserInteractionEnabled = true
                if isEditMode {
                    closeButton.isHidden = false
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        annotationTextView.delegate = self
        annotationTextView.textContainer.lineFragmentPadding = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func didTapCloseButton(_ sender: Any) {
        guard let annotation = annotation else {
            return
        }
        delegate?.annotationCell?(annotationCell: self, removedAnnotation: annotation)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        saveAnnotation()
    }
    
    fileprivate func saveAnnotation() {
        guard let annotation = annotation, let annotationText = annotationTextView.text, !annotationText.isEmpty else {
            annotationTextView.layer.borderColor = UIColor.red.cgColor
            annotationTextView.layer.borderWidth = 1.0
            return
        }
        annotationTextView.layer.borderWidth = 0
        annotationTextView.resignFirstResponder()
        
        annotation.text = annotationTextView.text!
        annotation.timestamp = timestampFloat!
        delegate?.annotationCell?(annotationCell: self, addedAnnotation: annotation)
    }
}

extension AnnotationCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        saveButton.isEnabled = annotationTextView.text!.characters.count > 0
    }
}
