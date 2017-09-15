//
//  EditViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 12/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI
import CoreImage


enum CurrentFilter {
    case Sepia
    case Blur
    case Saturation
    case Brightness
    case Contrast
    case Temp
    case Tint
    case None
}

class EditViewController: UIViewController {

    fileprivate var currentAsset: PHAsset!
    fileprivate var currentImage: UIImage!
    
    @IBOutlet weak var editedImage: UIImageView!
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var depthSwitch: UISwitch!
    @IBOutlet weak var focalSwitch: UISwitch!
    
    let context = CIContext()
    let filterSepia = CIFilter(name: "CISepiaTone")!
    let filterBlur = CIFilter(name: "CIMotionBlur")!
    let filterControls = CIFilter(name: "CIColorControls")!
    let filterTempAndTint = CIFilter(name: "CITemperatureAndTint")!
    
    var currentFilter: CurrentFilter = .None
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editedImage.setImage(withAsset: currentAsset)
        currentImage = editedImage.image
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCrop(_ sender: UIButton) {
        
        let clippedRect = CGRect(x: editedImage.frame.origin.x + 10,
                                 y: editedImage.frame.origin.y + 10,
                                 width: editedImage.frame.size.width - 10,
                                 height: editedImage.frame.size.height - 10)
        
        guard let ref = editedImage.image!.cgImage!.cropping(to: clippedRect) else {
            return
        }
        
        let newImage = UIImage(cgImage: ref)
        editedImage.image = newImage
        
    }
    
    @IBAction func onTemp(_ sender: UIButton) {
        setTempFilter()
    }
    
    @IBAction func onContrast(_ sender: UIButton) {
        setContrastFilter()
    }
    
    @IBAction func onTint(_ sender: UIButton) {
        setTintFilter()
    }
    
    @IBAction func onBrightness(_ sender: UIButton) {
        setBrightnessFilter()
    }
    
    @IBAction func onSaturation(_ sender: UIButton) {
        setSaturationFilter()
    }
    
    
    @IBAction func onDepthToggle(_ sender: UISwitch) {
    }
    
    @IBAction func onFocalToggle(_ sender: UISwitch) {
    }
    
    @IBAction func onValueChange(_ sender: UISlider) {
        let value = sender.value
        updateValues(value: value)
    }
}

//MARK: Effect Actions
extension EditViewController {
    
    func updateValues(value: Float) {
        var filter: CIFilter = CIFilter()
        switch currentFilter {
        case .Sepia:
            filterSepia.setValue(value, forKey: kCIInputIntensityKey)
            filter = filterSepia
            break
        case .Temp:
            let scale: CGFloat = CGFloat(6500 * value)
            let vector = CIVector(x: scale, y: 0)
            filterTempAndTint.setValue(vector, forKey: kCIInputNeutralTemperatureKey)
        case .Contrast:
            filterControls.setValue(value, forKey: kCIInputSaturationKey)
            filter = filterControls
            break
        case .Brightness:
            filterControls.setValue(value, forKey: kCIInputBrightnessKey)
            filter = filterControls
            break
        case .Saturation:
            filterControls.setValue(value, forKey: kCIInputSaturationKey)
            filter = filterControls
            break
        case .Tint:
            let scale: CGFloat = CGFloat(6500 * value)
            let vector = CIVector(x: scale, y: 0)
            filterControls.setValue(vector, forKey: kCIInputNeutralTintKey)
        default:
            return
        }
        
        guard let tempCGImage = currentImage.cgImage else {
            return
        }
        let image = CIImage(cgImage: tempCGImage)
        filter.setValue(image, forKey: kCIInputImageKey)
        
        guard let result = filter.outputImage else {
            return
        }
        
        guard let cgImage = context.createCGImage(result, from: result.extent) else {
            return
        }
        
        editedImage.image = UIImage(cgImage: cgImage)
        context.clearCaches()
    }
    
    func setTempFilter() {
        currentFilter = .Temp
    }
    
    func setContrastFilter() {
        currentFilter = .Contrast
    }
    
    func setBrightnessFilter() {
        currentFilter = .Brightness
    }
    
    func setTintFilter() {
        currentFilter = .Tint
    }
    
    func setSaturationFilter() {
        currentFilter = .Saturation
    }
}

//Instance Factory
extension EditViewController {
    
    static func getInstance(asset: PHAsset) -> EditViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        let controller = story.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        controller.currentAsset = asset
        return controller
    }
    
}
