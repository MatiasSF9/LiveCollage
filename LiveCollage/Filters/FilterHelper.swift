//
//  FilterHelper.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 19/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import CoreImage

protocol FilterHelperProtocol {
    
    //Add or Update filter values
    func addFiterToChain(filter: CIFilter, value: CGFloat, depthEnabled: Bool, depth: CGFloat, slope: CGFloat) 
    //Remove filter with given name
    func removeFilter(filterName: String) -> UIImage
    //Removes last filter
    func undo() -> UIImage
    //Gets filter with given name
    func getFilter(filterName: String) -> FilterStateEntry?
}


class FilterHelper: FilterHelperProtocol {
    
    fileprivate let context = CIContext()
    private let filterChain = FilterState()
    fileprivate let frame:CGRect!
    private let editedImage: CIImage!
    private var disparityImage: CIImage?
    
    
    init(editedImage: CIImage, frame: CGRect) {
        self.editedImage = editedImage
        self.frame = frame
    }
    
    func setDisparity(image: CIImage) {
        self.disparityImage = image
    }
    
    //Add or Update filter values
    func addFiterToChain(filter: CIFilter, value: CGFloat, depthEnabled: Bool, depth: CGFloat, slope: CGFloat) {
        if getFilter(filterName: filter.name) != nil {
            filterChain.replaceEntry(filter: filter, value: value, depthEnabled: depthEnabled, valueDepth: depth, valueSlope: slope)
        } else {
            filterChain.addFilterStateEntry(filter: filter, value: value, depthEnabled: depthEnabled, depth: depth, slope: slope)
        }
    }
    
    //Remove filter with given name
    func removeFilter(filterName: String) -> UIImage {
        filterChain.removeFilter(filterName: filterName)
        return applyChain()
    }
    
    //Removes last filter
    func undo() -> UIImage {
        filterChain.removeLast()
        return applyChain()
    }
    
    //Gets filter with given name
    func getFilter(filterName: String) -> FilterStateEntry? {
        return filterChain.getStateForFilter(name: filterName)
    }
    
    func applyDepthChain() -> UIImage{
        Logger.log(type: .DEBUG, string: "Applying depth filter chain")
        
        //Get unedited image
        guard var tempForeground = editedImage else {
            Logger.log(type: .WARNING, string: "Unable to blend images")
            return UIImage(ciImage: editedImage)
        }
        
        for i in (0..<filterChain.entries.count).reversed() {
            //Last entry
            let entry = filterChain.entries[i]
            guard let tempBackground = applyFilter(filter: entry.filter, image: tempForeground) else {
                //TODO: handle errors
                Logger.log(type: .WARNING, string: "Unable to blend images")
                return UIImage(ciImage: editedImage)
            }
            
            if entry.depthEnabled{
                guard let blend = applyBlend(background: tempBackground, disparity: disparityImage!,
                                             foreground: tempForeground, slope: entry.valueSlope,
                                             bias: entry.valueDepth) else {
                    //TODO: handle errors
                    Logger.log(type: .WARNING, string: "Unable to blend images")
                    return UIImage(ciImage: editedImage)
                }
                tempForeground = blend
            } else {
                tempForeground = tempBackground
            }
        }
        return UIImage(ciImage: tempForeground)
    }
    
    //Applies filter change to UIImage
    func applyChain() ->  UIImage {
        Logger.log(type: .DEBUG, string: "Applying filter chain")
        
        var tempCIImage = editedImage
        for entry in filterChain.entries {
            if tempCIImage == nil {
                Logger.log(type: .WARNING, string: "No filted applied. Returning default image.")
                return UIImage(ciImage: editedImage)
            } else {
                tempCIImage = applyFilter(filter: entry.filter, image: tempCIImage!)
            }
        }
        Logger.log(type: .DEBUG, string: "Filter chain end")
        return UIImage(ciImage: tempCIImage!)
    }

    
    private func applyFilter(filter: CIFilter, image: CIImage) -> CIImage? {
        Logger.log(type: .DEBUG, string: "Applying filter \(filter.name)")
        
        filter.setValue(image, forKey: kCIInputImageKey)
        
        guard let result = filter.outputImage else {
            Logger.log(type: .WARNING, string: "Unable to generate output image from filter \(filter.name)")
            return nil
        }
        context.clearCaches()
        return result
    }
    
    
    //Applies blend mask for depth enabled images
    private func applyBlend(background: CIImage, disparity: CIImage, foreground: CIImage, slope: CGFloat, bias: CGFloat) -> CIImage? {
        
        let mask = AssetHelper.shared().getBlendMask(disparityImage: disparity, slope:  slope, bias: bias)
        return AssetHelper.shared().blendImages(background: background, foreground: foreground, mask: mask)
    }
}
