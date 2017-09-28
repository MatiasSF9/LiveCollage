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
    func addFiterToChain(filter: CIFilter, value: CGFloat, depthValue: CGFloat) -> UIImage
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
    private let editedImage: UIImage!
    private var disparityImage: CIImage?
    
    
    init(editedImage: UIImage, frame: CGRect) {
        self.editedImage = editedImage
        self.frame = frame
    }
    
    func setDisparity(image: CIImage) {
        self.disparityImage = image
    }
    
    //Add or Update filter values
    func addFiterToChain(filter: CIFilter, value: CGFloat, depthValue: CGFloat) -> UIImage {
        if getFilter(filterName: filter.name) != nil {
            filterChain.replaceEntry(filter: filter, value: value, depthValue: depthValue)
        } else {
            filterChain.addFilterStateEntry(filter: filter, value: value, valueDepth: depthValue)
        }
        return applyChain()
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
    
    //Applies filter change to UIImage
    func applyChain() ->  UIImage {
        Logger.log(type: .DEBUG, string: "Applying filter chain")
        var tempCGImage = editedImage.cgImage
        for entry in filterChain.entries {
            tempCGImage = applyFilter(filter: entry.filter, image: tempCGImage!)
            if tempCGImage == nil {
                Logger.log(type: .WARNING, string: "No filted applied. Returning default image.")
                return UIImage(cgImage: editedImage.cgImage!)
            }
        }
        Logger.log(type: .DEBUG, string: "Filter chain end")
        return UIImage(cgImage: tempCGImage!)
    }

    
    private func applyFilter(filter: CIFilter, image: CGImage) -> CGImage? {
        Logger.log(type: .DEBUG, string: "Applying filter \(filter.name)")
        filter.setValue(CIImage(cgImage: image), forKey: kCIInputImageKey)
        guard let result = filter.outputImage else {
            Logger.log(type: .WARNING, string: "Unable to generate output image from filter \(filter.name)")
            return nil
        }
        guard let cgImage = context.createCGImage(result, from: result.extent) else {
            Logger.log(type: .WARNING, string: "Unable to generate CGImage from context with filter \(filter.name)")
            return nil
        }
        context.clearCaches()
        Logger.log(type: .DEBUG, string: "Filter \(filter.name) applied!")
        return cgImage
    }
    
    //Applies blend mask for depth enabled images
    private func applyBlend() {
        let mask = AssetHelper.shared().getBlendMask(disparityImage: disparityImage!,
                                                     slope:  CGFloat(slopeSlider.value),
                                                     bias: CGFloat(depthSlider.value))
        
        var chainedFilter = filterHelper.applyChain()
        chainedFilter = chainedFilter.resize(targetSize: (currentImage?.size)!)!
        
        let currentCIImage = CIImage(cgImage: (currentImage?.cgImage)!)
        
        
        let blend = AssetHelper.shared().blendImages(background: CIImage(cgImage: chainedFilter.cgImage!),
                                                     foreground: currentCIImage,
                                                     mask: mask)
    }
}
