//
//  FilterCollectionCell.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 13/11/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

class FilterCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var lblName: UILabel?
    
    
    func configure(image: UIImage, name: String) {
        imageView?.image = image
        lblName?.text = name
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
    }
}
