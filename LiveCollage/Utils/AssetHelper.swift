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
        //TODO: use Cloud
        // Fetch the image from iCloud if necessary and provide progress
//        options.networkAccessAllowed = YES;
//        options.progressHandler = ^(BOOL degraded, double progress, NSError *error,
//            BOOL *stop) {
//                [self updateUserVisibleProgress:progress error:error];
//        };
        manager.requestImage(for: asset, targetSize: forSize, contentMode: .aspectFill, options: options, resultHandler: resultHandler)
    }
    
    func stopCaching() {
        manager.stopCachingImagesForAllAssets()
    }
    
    
//    func getAssetForEdition(asset: PHAsset) {
//        // Get the input from the asset
//        let options = PHContentEditingInputRequestOptions()
//        asset.requestContentEditingInput(with: options) { (input, info) in
//
//            guard let url = input?.fullSizeImageURL else {
//                return
//            }
//            guard let orientation = input?.fullSizeImageOrientation else {
//
//            }
//
//            let inputImage = CIImage(contentsOf: url)
////            input?.fullSizeImageOrientation = orientation
//
//        }
//    }
    
    func saveEditedAsset(input: PHContentEditingInput, jpegData: Data, adjustmentData: PHAdjustmentData) {
        // Create the output
        let output = PHContentEditingOutput(contentEditingInput: input)
//        let options = WritingOptions()
//        jpegData.write(to: output.renderedContentURL, options: options)
        output.adjustmentData = adjustmentData
        
        PHPhotoLibrary.shared().performChanges({
            
        }) { (success, error) in
            
        }
        
    }
    
}
