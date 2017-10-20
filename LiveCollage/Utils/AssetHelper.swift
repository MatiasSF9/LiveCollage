//
//  AssetHelper.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/20/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import Photos
import ImageIO
import AVFoundation
import CoreImage
import Foundation

struct ImageData {
    var data: Data?
    var info: [AnyHashable: Any]?
    var orientation: UIImageOrientation?
}

class AssetHelper {
    
    static let instance = AssetHelper()
    
    fileprivate var manager = PHCachingImageManager()
    fileprivate var editManager = PHContentEditingInput()
    
    static func shared() -> AssetHelper {
        return instance
    }
    
    //Gets image from PHAsset.
    //Returns image in callback
    func getAsset(asset: PHAsset, forSize: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Swift.Void) {
        // Request an image for the asset from the PHCachingImageManager.
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isSynchronous = true
        //TODO: use Cloud
        manager.requestImage(for: asset, targetSize: forSize, contentMode: .aspectFill,
                             options: options, resultHandler: resultHandler)
    }
    
    func stopCaching() {
        manager.stopCachingImagesForAllAssets()
    }
}


//MARK: Editing retrieval
extension AssetHelper {
    
    //Gets asset enabled for editing
    func getAssetForEdition(asset: PHAsset) {
        // Get the input from the asset
        let options = PHContentEditingInputRequestOptions()
        asset.requestContentEditingInput(with: options) { input, info in
            _ = input?.fullSizeImageURL
        }
    }
    
    //Gets image data from PHAsset
    func getImageData(asset: PHAsset, resultHandler: @escaping (ImageData) -> Swift.Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.version = PHImageRequestOptionsVersion.original
        options.isNetworkAccessAllowed = true
        
        manager.requestImageData(for: asset, options: options) { (imageData, dataType, orientation, info) in
            
            guard let data = imageData?.CFData() else {
                resultHandler(ImageData(data: nil, info: nil, orientation: nil))
                return

            }
            let properties = self.imagePropertiesFromImageData(imageData: data) as? [AnyHashable: Any]
            resultHandler(ImageData(data: imageData, info: properties, orientation: orientation))
            
        }
    }
    
    //Awful code. Fuck CFFoundation!!
    func hasDepthInformation(info: [AnyHashable : Any]) -> Bool {
        guard let content = info[kCGImagePropertyFileContentsDictionary] as? [AnyHashable : Any] else {
            return false
        }
        let count = content[kCGImagePropertyImageCount] as? Int
        if count! < 1 {
            return false
        }
        guard let images = content[kCGImagePropertyImages] as? [Any] else {
            return false
        }
        
        guard let image = images[0] as? [AnyHashable: Any] else {
            return false
        }
        guard let auxilaryData = image[kCGImagePropertyAuxiliaryData] as? [Any] else {
            return false
        }
        guard let aux = auxilaryData[0] as? [AnyHashable: Any] else {
            return false
        }
        let dataType: CFString = aux[kCGImagePropertyAuxiliaryDataType] as! CFString
        if dataType == kCGImageAuxiliaryDataTypeDisparity {
            Logger.VERBOSE(message: "Disparity data found!")
            return true
        }
        return false
    }
    
    //Get images properties
    func imagePropertiesFromImageData(imageData: CFData) -> CFDictionary? {
        Logger.log(type: .VERBOSE, string: "Getting image properties")
        if let cgImageSource = CGImageSourceCreateWithData(imageData, nil) {
            
            if let cgImageProperties = CGImageSourceCopyProperties(cgImageSource, nil) {
                Logger.log(type: .VERBOSE, string: "Image properties found!")
                return cgImageProperties
            }
        }
        Logger.log(type: .WARNING, string: "No image properties found")
        return nil
    }
    
    func saveEditedAsset(input: PHContentEditingInput, jpegData: Data, adjustmentData: PHAdjustmentData) {
        //TODO: Save image
    }
    
}
