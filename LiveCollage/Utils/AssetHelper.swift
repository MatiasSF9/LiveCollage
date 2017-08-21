//
//  AssetHelper.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/20/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import Photos

class AssetHelper {
    
    static let shared = AssetHelper()
    
    fileprivate var manager = PHCachingImageManager()
    
    func getAsset(asset: PHAsset, forSize: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Swift.Void) {
        // Request an image for the asset from the PHCachingImageManager.
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        manager.requestImage(for: asset, targetSize: forSize, contentMode: .aspectFill, options: options, resultHandler: resultHandler)
    }
    
    func stopCaching() {
        manager.stopCachingImagesForAllAssets()
    }
    
}
