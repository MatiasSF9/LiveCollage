//
//  HB2Filter.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 10/11/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import CoreImage

class HB2Filter: CIFilter {

    @objc dynamic var inputImage:CIImage?
    var exposure = 0.45
    var saturation = 0.8
    var contrast = 1.01
    var neutral = CIVector(x:6500,y:10)
    var targetNeutral = CIVector(x:6500,y:0)
    
    override var name: String {
        get { return "HB2Filter" }
        set { }
    }
    
    override open var inputKeys: [String] {
        get { return [kCIInputImageKey] }
    }

    override func setDefaults() {
        super.setDefaults()
        exposure = 0.45
        saturation = 0.8
        contrast = 1.01
        neutral = CIVector(x:6000,y:0)
        targetNeutral = CIVector(x:6500,y:0)
    }
    
    override var outputImage: CIImage? {
        
        if inputImage == nil {
            return nil
        }
        
        let filter = CIFilter(name: "CIExposureAdjust")
        filter?.setValue(exposure, forKey: "inputEV")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        var temp = filter?.outputImage
        
        let controls = CIFilter(name: "CIColorControls")
        controls?.setValuesForKeys([kCIInputSaturationKey : saturation, kCIInputContrastKey: contrast])
        controls?.setValue(temp, forKey: kCIInputImageKey)
        temp = controls?.outputImage
        
        let temperature = CIFilter(name: "CITemperatureAndTint")
        temperature?.setValue(neutral, forKey: "inputNeutral")
        temperature?.setValue(targetNeutral, forKey: "inputTargetNeutral")
        temperature?.setValue(temp, forKey: kCIInputImageKey)
        return temperature?.outputImage
    }
    
}
