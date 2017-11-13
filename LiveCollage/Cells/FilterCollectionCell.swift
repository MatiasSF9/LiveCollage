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
    
    private var filter: CIFilter?
    private var image: CIImage?
    
    func configure(ciimage: CIImage, filter: CIFilter) {
        self.image = ciimage
        self.filter = filter
        
        filter.setValue(self.image, forKey: kCIInputImageKey)
        guard let output = filter.outputImage else {
            return
        }
        lblName?.text = filter.name
        imageView?.image = UIImage(ciImage: output)
    }
    
    func getFilter() -> CIFilter? {
        return filter
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
        filter = nil
    }
}
