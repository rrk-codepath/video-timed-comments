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
    @objc optional func annotationCell(annotationCell: AnnotationCell, tappedTimestamp timestamp: Float)
}

class AnnotationCell: UITableViewCell {
    @IBOutlet weak var annotationTextField: UITextField!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    weak var delegate: AnnotationCellDelegate?
    
    var timestampFloat: Float?
    
    var isEditMode: Bool = false {
        didSet {
            annotationTextField.isUserInteractionEnabled = isEditMode
            addButton.isHidden = !isEditMode
        }
    }
    
    var annotation: Annotation? {
        didSet {
            if let annotation = annotation {
                annotationTextField.text = annotation.text
                timestampFloat = annotation.timestamp
                timestampLabel.text = annotation.timestamp.joompedBeautify()
                timestampLabel.isHidden = false
                annotationTextField.isUserInteractionEnabled = true
                annotationTextField.becomeFirstResponder()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let timestampTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTimestamp(_:)))
        timestampLabel.addGestureRecognizer(timestampTapRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func didTapTimestamp(_ sender: Any) {
        delegate?.annotationCell?(annotationCell: self, tappedTimestamp: timestampFloat!)
    }
    
    @IBAction func didTapAddButton(_ sender: Any) {
        guard let annotationText = annotationTextField.text, !annotationText.isEmpty else {
            return
        }
        annotation?.text = annotationTextField.text!
        annotation?.timestamp = timestampFloat!
        delegate?.annotationCell?(annotationCell: self, addedAnnotation: annotation!)
    }
}
