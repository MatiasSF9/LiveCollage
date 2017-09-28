//
//  UIImageView+PHAsset.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 12/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI

extension UIImageView {
    //Retrieve image from asset and add it to imageview
 func setImage(withAsset asset: PHAsset) {
        AssetHelper.shared().getAsset(asset: asset, forSize: self.frame.size) { image, _ in
            if image != nil {
                Logger.log(type: .DEBUG, string: "Adding image \(asset) to UIImageView")
                self.image = image
                
            } else {
                Logger.log(type: .WARNING, string: "Failure to add image \(asset) to UIImageView")
            }
        }
    }
    
}
