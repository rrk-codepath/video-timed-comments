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
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var annotationLabel: UILabel!
    weak var delegate: AnnotationCellDelegate?
    
    var timestampFloat: Float?
    
    var isEditMode: Bool = false {
        didSet {
            annotationLabel.isHidden = isEditMode
            annotationTextField.isHidden = !isEditMode
            saveButton.isHidden = !isEditMode
        }
    }
    
    var annotation: Annotation? {
        didSet {
            if let annotation = annotation {
                annotationTextField.text = annotation.text
                annotationLabel.text = annotation.text
                timestampFloat = annotation.timestamp
                timestampLabel.text = annotation.timestamp.joompedBeautify()
                timestampLabel.isHidden = false
                annotationTextField.isUserInteractionEnabled = true
            }
        }
    }
    
    @IBAction func editingDidChange(_ sender: Any) {
        saveButton.isEnabled = annotationTextField.text!.characters.count > 0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func didTapSaveButton(_ sender: Any) {
        guard let annotationText = annotationTextField.text, !annotationText.isEmpty else {
            annotationTextField.layer.borderColor = UIColor.red.cgColor
            annotationTextField.layer.borderWidth = 1.0
            return
        }
        annotationTextField.layer.borderWidth = 0
        annotation?.text = annotationTextField.text!
        annotation?.timestamp = timestampFloat!
        delegate?.annotationCell?(annotationCell: self, addedAnnotation: annotation!)
    }
}
