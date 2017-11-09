//
//  FilterHelper.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 19/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import CoreImage

enum FilterSwitch: Int {
    case Background = 0, Foreground
}

protocol FilterHelperProtocol {
    
    //Add or Update filter values
    func addFiterToChain(filter: CIFilter, value: CGFloat, depthEnabled: Bool, depth: CGFloat, slope: CGFloat, filterSwitch: FilterSwitch)
    //Remove filter with given name
    func removeFilter(filterName: String, filterSwitch: FilterSwitch) -> UIImage
    //Removes last filter
    func undo(filterSwitch: FilterSwitch) -> UIImage
    //Gets filter with given name
    func getFilter(filterName: String, filterSwitch: FilterSwitch) -> FilterStateEntry?
    
    //Gets last depth value
    func getDepth(filterSwitch: FilterSwitch) -> CGFloat
}


class FilterHelper: FilterHelperProtocol {
    
    private let editedImage: CIImage!
    private var disparityImage: CIImage?
    
    private var depthEnabled: Bool = false
    private var valueDepthBackground: CGFloat = 1.0
    private var valueDepthForeground: CGFloat = 1.0
    private let filterChainBackground = FilterState()
    private let filterChainForeground = FilterState()
    
    fileprivate let context = CIContext()
    fileprivate let filterCube = ColorCube.colorCubeFilterForChromaKey(valueFilter: 0.95)
    fileprivate let frame:CGRect!
    
    
    init(editedImage: CIImage, frame: CGRect) {
        self.editedImage = editedImage
        self.frame = frame
    }
    
    func setDisparity(image: CIImage) {
        self.disparityImage = image
    }
    
    //Add or Update filter values
    func addFiterToChain(filter: CIFilter, value: CGFloat, depthEnabled: Bool,
                         depth: CGFloat, slope: CGFloat, filterSwitch: FilterSwitch) {
        
        var chain: FilterState!
        if filterSwitch == .Foreground {
            chain = filterChainForeground
            valueDepthForeground = depth
        } else {
            chain = filterChainBackground
            valueDepthBackground = depth
        }
        
        if chain.getStateForFilter(name: filter.name) != nil {
            chain.replaceEntry(filter: filter, value: value)
        } else {
            chain.addFilterStateEntry(filter: filter, value: value)
        }
    }
    
    //Remove filter with given name
    func removeFilter(filterName: String, filterSwitch: FilterSwitch) -> UIImage {
        if filterSwitch == .Background {
            filterChainBackground.removeFilter(filterName: filterName)
        } else {
            filterChainForeground.removeFilter(filterName: filterName)
        }
        return applyChain()
    }
    
    //Removes last filter
    func undo(filterSwitch: FilterSwitch) -> UIImage {
        switch filterSwitch {
        case FilterSwitch.Foreground:
            filterChainForeground.removeLast()
            break
        case FilterSwitch.Background:
            filterChainBackground.removeLast()
            break
        }
        return applyChain()
    }
    
    //Gets filter with given name
    func getFilter(filterName: String, filterSwitch: FilterSwitch) -> FilterStateEntry? {
        switch filterSwitch {
        case .Foreground:
            return filterChainForeground.getStateForFilter(name: filterName)
        case .Background:
            return filterChainBackground.getStateForFilter(name: filterName)
        }
        
    }
    
    func applyDepthChain() -> UIImage{
        Logger.log(type: .DEBUG, string: "Applying depth filter chain")
        
        let background = processFilters(filterSwitch: .Background)
//        return UIImage(ciImage: background)
        let foregrund = processFilters(filterSwitch: .Foreground)
//        return UIImage(ciImage: foregrund)
        

        guard let blend = applyBlend(background: background, disparity: disparityImage!,
                   foreground: foregrund, slope: 1,
                   bias: valueDepthForeground, inverted: false) else {
                    //TODO: catch error
                    return UIImage(ciImage: editedImage)
        }
        return UIImage(ciImage: blend)
    }
    
    private func processFilters(filterSwitch: FilterSwitch) -> CIImage {
        var chain: FilterState!
        var depth: CGFloat!
        
        switch filterSwitch {
        case .Background:
            chain = filterChainBackground
            depth = valueDepthBackground
            break
        case .Foreground:
            chain = filterChainForeground
            depth = valueDepthForeground
            break
        }
        
        var processesImage: CIImage?
        //Apply effects to background
        for i in (0..<chain.entries.count).reversed() {
            let entry = chain.entries[i]
            if processesImage == nil {
                processesImage = applyFilter(filter: entry.filter, image: editedImage)
            } else {
                processesImage = applyFilter(filter: entry.filter, image: processesImage!)
            }
        }
        
        if processesImage == nil {
            //TODO: handle errors
            Logger.log(type: .WARNING, string: "Unable to apply filter")
            return editedImage
        }
        
        var imageBlend: CIImage?
        if filterSwitch == .Background {
            imageBlend = applyBlend(background: processesImage!, disparity: disparityImage!,
                                              foreground: editedImage, slope: 1, bias: depth,
                                              inverted: false)
        } else {
            imageBlend = applyBlend(background: processesImage!, disparity: disparityImage!,
                                    foreground: editedImage, slope: 1, bias: depth,
                                    inverted: true)
        }
        
        if imageBlend == nil {
            //TODO: handle errors
            Logger.log(type: .WARNING, string: "Unable to blend images")
            return editedImage
        }
        
        return imageBlend!
    }
    
    
    
    //Applies filter change to UIImage
    func applyChain() ->  UIImage {
        Logger.log(type: .DEBUG, string: "Applying filter chain")
        
        var tempCIImage = editedImage
        for entry in filterChainBackground.entries {
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
    private func applyBlend(background: CIImage, disparity: CIImage, foreground: CIImage, slope: CGFloat, bias: CGFloat, inverted: Bool) -> CIImage? {
        
        let mask = getBlendMask(disparityImage: disparity, slope:  slope, bias: bias, inverted: inverted)
        return blendImages(background: background, foreground: foreground, mask: mask)
    }
    
    func getDepth(filterSwitch: FilterSwitch) -> CGFloat {
        switch filterSwitch {
        case .Background:
            return valueDepthBackground
        case .Foreground:
            return valueDepthForeground
        }
    }
    
}
//MARK: Disparity and blends
extension FilterHelper {
    //Builds a blend mask
    func getBlendMask(disparityImage: CIImage, slope: CGFloat, bias: CGFloat, inverted: Bool) -> CIImage {
        
        //Turns red scale into grayscale usable for blend
        var mask = disparityImage.applyingFilter("CIMaximumComponent")
        
        
        //Scales and offset disparity values according to the slider arguments.
        //CIColorMatrix: Multiplies source color values and adds a bias factor to each color component
        mask = mask.applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: slope, y: 0, z: 0, w: 0),
                                                                 "inputGVector": CIVector(x: 0, y: slope, z: 0, w: 0),
                                                                 "inputBVector": CIVector(x: 0, y: 0, z: slope, w: 0),
                                                                 "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                                                                 "inputBiasVector": CIVector(x: bias, y: bias, z: bias, w: 0)])
        
        if inverted {
            mask = mask.applyingFilter("CIColorInvert")
        }
        //Clamp the mask values to [0,1]
        //CIFilterClamp: Modifies color values to keep them within a specified range.)
        mask = mask.applyingFilter("CIColorClamp")
        
        return filterGreys(ciimage: mask)
    }
    
    //Blends background and foreground images according to the provided mask
    func blendImages(background: CIImage, foreground: CIImage, mask: CIImage) -> CIImage {
        return foreground.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey : background, kCIInputMaskImageKey: mask])
    }
    
    func filterGreys(ciimage: CIImage) -> CIImage {
        
        filterCube.setValue(ciimage, forKey: kCIInputImageKey)
        
        guard let output = filterCube.outputImage else {
            return ciimage
        }
        return output
    }
}
