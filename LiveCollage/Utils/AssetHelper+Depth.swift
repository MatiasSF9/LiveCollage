//
//  AssetHelper+Depth.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 26/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import AVFoundation
import CoreImage

//MARK: Data and Depth retrieval

//Seps for using Depth:
// 1 - Get image properties asynchronously and check it has depth info
// 2 - Retrieve depth map
// 3 - Translate to disparity image
// 4 - Generate mask from disparity
// 5 - Generate background image
// 6 - Apply blend between original and background using mask

extension AssetHelper {
    
    //MARK: AVDEPTHDATA
    //Get depth information from image URL
    func getDepthDataFromURL(imageURL: URL) -> AVDepthData? {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL.CFURL()!, nil) else {return nil}
        return getDepthDataFromSource(source: imageSource)
    }
    
    func depthDataFromImageData(data: CFData) -> AVDepthData? {
        Logger.log(type: .VERBOSE, string: "Getting Depth Data from Image")
        guard let imageSource = CGImageSourceCreateWithData(data, nil) else {return nil}
        return getDepthDataFromSource(source: imageSource)
    }
   
    //MARK: CIIMage Depth Image
    //Convert Image Data to Disparity Image
    func getDisparityImage(imageData: Data) -> CIImage? {
        //Create Depth Image
        guard let depthImage = CIImage(data: imageData, options: [kCIImageAuxiliaryDepth: true]) else {
            return nil
        }
        return getDisparityFromDepthImage(depthImage: depthImage)
    }
    
    //Sample Disparity Map to Min - Max
    func sampleDiparity(disparityImage: CIImage, rect: CGRect) -> (min: Float, max: Float){
        //Apply filter with the Sample Rect from the user's tap.
        let minMaxImage = disparityImage.clampedToExtent().applyingFilter("CIAreaMinMaxRed", parameters: [kCIInputExtentKey : CIVector(cgRect: rect)])
        //Four byte buffer to store single pixel value
        var pixel = [UInt8](repeatElement(0, count: 4))
        
        //Render the image to a 1x1 rect.
        CIContext().render(minMaxImage, toBitmap: &pixel, rowBytes: 4,
                           bounds: CGRect(x:0, y: 0, width:1, height:1),
                           format: kCIFormatRGBA8, colorSpace: nil)
        
        //The max is stored in the green channel. Min is in the red.
        return (min: Float(pixel[0]) / 255.0, max: Float(pixel[1]) / 255.0)
    }
    
    //Builds a blend mask
    func getBlendMask(disparityImage: CIImage, slope: CGFloat, bias: CGFloat) -> CIImage {
        
        //Scales and offset disparity values according to the slider arguments.
        //CIColorMatrix: Multiplies source color values and adds a bias factor to each color component
        let mask = disparityImage.applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: slope, y: 0, z: 0, w: 0),
                                                                               "inputGVector": CIVector(x: 0, y: slope, z: 0, w: 0),
                                                                               "inputBVector": CIVector(x: 0, y: 0, z: slope, w: 0),
                                                                               "inputBiasVector": CIVector(x: bias, y: bias, z: bias, w: 0)])
        //Clamp the mask values to [0,1]
        //CIFilterClamp: Modifies color values to keep them within a specified range.)
        return mask.applyingFilter("CIColorClamp")
    }
    
    //Blends background and foreground images according to the provided mask
    func blendImages(background: CIImage, foreground: CIImage, mask: CIImage) -> CIImage {
        return foreground.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey : background, kCIInputMaskImageKey: mask])
    }
    
}

//MARK: Private Methods
extension AssetHelper {
    
    //Convert Image Source to AVDepthData
    fileprivate func getDepthDataFromSource(source: CGImageSource) -> AVDepthData? {
        let auxData = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable: Any]
        if auxData != nil {
            do {
                // Create a depth data object from auxiliary data
                var depthData = try AVDepthData(fromDictionaryRepresentation: auxData!)
                // Check native depth data type
                if depthData.depthDataType != kCVPixelFormatType_DisparityFloat16 {
                    //Convert to half float disparity data
                    depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
                }
                
                let depthMap: CVPixelBuffer = depthData.depthDataMap
                Logger.log(type: .VERBOSE, string: "Depth Data found!")
                return depthData
            } catch {
                Logger.log(type: .ERROR, string: "Catching error from Depth Data retrieval")
                return nil
            }
        }
        Logger.log(type: .WARNING, string: "No depth data found")
        return nil
    }

    //Convert Depth Image to Disparity Image
    fileprivate func getDisparityFromDepthImage(depthImage: CIImage) -> CIImage? {
        //Get AVDepthData Object
        let depthData = depthImage.depthData
        //Convert to disparity
        let disparityImage = depthImage.applyingFilter("CIDepthToDisparity")
        
        return disparityImage
    }
    
    //For some reason is rotates -90degrees clockwise
    func rotateImage(image: CIImage, orientation: CGImagePropertyOrientation) -> CIImage {
        let transform = image.orientationTransform(for: orientation)
        return image.transformed(by: transform)
    }
}
