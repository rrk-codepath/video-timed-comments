//
//  AnnotationCell.swift
//  Joomped
//
//  Created by Rahul Pandey on 11/11/16.
//  Copyright © 2016 Joomped. All rights reserved.
//

import UIKit

@objc protocol AnnotationCellDelegate: class {
    @objc func annotationCell(annotationCell: AnnotationCell, addedAnnotation newAnnotation: Annotation)
}


class AnnotationCell: UITableViewCell {
    @IBOutlet weak var annotationTextField: UITextField!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var isEditMode: Bool = false {
        didSet {
            if isEditMode {
                annotationTextField.isUserInteractionEnabled = true
                addButton.isHidden = false
            } else {
                annotationTextField.isUserInteractionEnabled = false
                addButton.isHidden = true
            }
        }
    }
    
    var annotation: Annotation? {
        didSet {
            if let annotation = annotation {
                annotationTextField.text = annotation.text
                // TODO: better formatting
                timestampLabel.text = String(annotation.timestamp)
                annotationTextField.isUserInteractionEnabled = true
                annotationTextField.becomeFirstResponder()
            }
        }
    }
    
    weak var delegate: AnnotationCellDelegate?
    
    @IBOutlet weak var addButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.backgroundColor = UIColor.red
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func didTapAddButton(_ sender: Any) {
        guard let annotationText = annotationTextField.text, !annotationText.isEmpty else {
            return
        }
        annotation?.text = annotationTextField.text!
        annotation?.timestamp = Float(timestampLabel.text!)!
        
//        if let annotationTime = annotationTime {
//            annotation.timestamp = annotationTime
//        }
        delegate?.annotationCell(annotationCell: self, addedAnnotation: annotation!)
    }
}
