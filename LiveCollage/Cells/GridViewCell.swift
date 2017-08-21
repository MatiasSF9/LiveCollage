//
//  GridViewCell.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/19/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

class GridViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var livePhotoBadgeImageView: UIImageView!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImage = nil
        livePhotoBadgeImageView.image = nil
    }
}

