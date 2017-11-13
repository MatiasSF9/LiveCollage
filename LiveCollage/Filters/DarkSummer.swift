//
//  DarkSummer.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 13/11/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

class DarkSummer: CIFilter {

    @objc dynamic var inputImage:CIImage?
    var exposure = 0.55
    var saturation = 1.2
    var contrast = 1.1
    var neutral = CIVector(x:6000,y:00)
    var targetNeutral = CIVector(x:6500,y:0)
    
    override var name: String {
        get { return "DarkSummer" }
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
