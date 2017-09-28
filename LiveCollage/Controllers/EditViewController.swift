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
import ImageIO

public let kColorFilter: String = "CIColorControls"
public let kTempFilter: String = "CITemperatureAndTint"
public let kMotionBlurFilter: String = "CIMotionBlur"

enum FilterType: Int {
    case Frame = 0, Brightness, Contrast, Temp, Fx, Blur, None
}

enum SliderType: Int {
    case Depth = 0, Focal, Slope
}

class EditViewController: UIViewController {

    //Current Assets
    fileprivate var currentAsset: PHAsset!
    
    //Current Image
    fileprivate var currentImage: UIImage?
    
    //Filter state handling
    fileprivate var filterHelper: FilterHelper!
    
    //Disparity Image
    fileprivate var disparityImage: CIImage?
    
    //Outlets
    @IBOutlet fileprivate weak var editedImage: UIImageView!
    @IBOutlet fileprivate weak var depthSlider: UISlider!
    @IBOutlet fileprivate weak var focalSlider: UISlider!
    @IBOutlet weak var slopeSlider: UISlider!
    @IBOutlet weak var depthLabel: UILabel!
    
    //Filters Setup
    fileprivate let context = CIContext()
    fileprivate var filterControls = CIFilter(name: kColorFilter)!
    fileprivate var filterTempAndTint = CIFilter(name: kTempFilter)!
    fileprivate var filterBlur = CIFilter(name: kMotionBlurFilter)!
    
    fileprivate var currentFilter: FilterType = .None
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editedImage.setImage(withAsset: currentAsset)
        filterHelper = FilterHelper(editedImage: editedImage.image!, frame: editedImage.frame)
        
        //Disable depth by default
        depthLabel.isHidden = true
        depthSlider.isEnabled = false
        
        //Get Image Data Async
        AssetHelper.shared().getImageData(asset: currentAsset) { [weak self] imageData in
            
            if imageData.info == nil  || imageData.data == nil{
                return
            }
            
            self?.currentImage = UIImage(data: imageData.data!)
            
            //Check if image has depth info
            if AssetHelper.shared().hasDepthInformation(info: imageData.info!) {
                self?.enableDepth(imageData: imageData.data!)
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: filter set
    //Binds the sliders to a specific filter
    @IBAction func onFilterSelected(_ sender: UIButton) {
        currentFilter = FilterType(rawValue: sender.tag)!
        
        switch FilterType(rawValue: sender.tag) {
        case .Frame?:
            break
        case .Brightness?:
            guard let state = filterHelper.getFilter(filterName: kColorFilter) else {
                return
            }
            filterControls = state.filter
            focalSlider.value = state.filter.value(forKey: kCIInputBrightnessKey) as! Float
            break
        case .Contrast?:
            guard let state = filterHelper.getFilter(filterName: kColorFilter) else {
                return
            }
            filterControls = state.filter
            focalSlider.value = state.filter.value(forKey: kCIInputContrastKey) as! Float
            break
        case .Temp?:
            guard let state = filterHelper.getFilter(filterName: kTempFilter) else {
                return
            }
            filterControls = state.filter
            focalSlider.value = state.filter.value(forKey: kCIInputNeutralTemperatureKey) as! Float
            break
        case .Fx?:
            break
        case .Blur?:
            guard let state = filterHelper.getFilter(filterName: kMotionBlurFilter) else {
                return
            }
            filterControls = state.filter
            let vector = state.filter.value(forKey: kCIInputRadiusKey) as! CIVector
            focalSlider.value = Float(vector.x / 6500)
            break
        case .None?: break
        default: break
            
        }
    }
    
    @IBAction func onValueChange(_ sender: UISlider) {
        
        let value = sender.value
        switch SliderType(rawValue: sender.tag) {
        case .Depth?:
            updateDepth(value: value)
            break
        case .Focal?:
            updateValues(value: value)
            break
        case .Slope?:
            updateSlope(value: value)
            break
        default: break

        }
    }
}

//MARK: Effect Actions
extension EditViewController {
    
    func enableDepth(imageData: Data) {
        depthLabel.isHidden = false
        depthSlider.isEnabled = true
        
        disparityImage = AssetHelper.shared().getDisparityImage(imageData: imageData)
        if disparityImage != nil {
            //Uncomment to display disparity image
            //editedImage.image = UIImage(ciImage: disparityImage!)
            Logger.VERBOSE(message: "Disparity image obtained!! 💕")
        }
    }
    
    func updateValues(value: Float) {
        var filter: CIFilter = CIFilter()
        switch currentFilter {
        case .Frame:
            //TODO:
            break
        case .Brightness:
            filterControls.setValue(value, forKey: kCIInputBrightnessKey)
            filter = filterControls
            break
        case .Contrast:
            filterControls.setValue(value, forKey: kCIInputContrastKey)
            filter = filterControls
            break
        case .Temp:
            let scale: CGFloat = CGFloat(6500 * value)
            let vector = CIVector(x: scale, y: 0)
            filterTempAndTint.setValue(vector, forKey: kCIInputNeutralTemperatureKey)
            break
        case .Fx:
            break
        case .Blur:
            filterBlur.setValue(value*100, forKey: kCIInputRadiusKey)
            filter = filterControls
            break
        default:
            return
        }
        
        _ = filterHelper.addFiterToChain(filter: filter, value: CGFloat(value), depthValue: CGFloat(depthSlider.value))
        updateRender()
    }

    func updateDepth(value: Float) {
        updateRender()
    }
    
    func updateSlope(value: Float) {
        updateRender()
    }
    
    private func updateRender() {
        if currentImage == nil {
            return
        }
        
                let scale = CGFloat(slopeSlider.value)
                let height = currentImage!.size.height
                let width = currentImage!.size.width
                let sample = AssetHelper.shared().sampleDiparity(disparityImage: disparityImage!,
                                                                 rect: CGRect(x: 0, y: CGFloat(depthSlider.value) * height,
                                                                              width: width ,
                                                                              height: height * scale))
        let mask = AssetHelper.shared().getBlendMask(disparityImage: disparityImage!,
                                                     slope:  CGFloat(slopeSlider.value),
                                                     bias: CGFloat(depthSlider.value))
        
        var chainedFilter = filterHelper.applyChain()
        chainedFilter = chainedFilter.resize(targetSize: (currentImage?.size)!)!
        
        let currentCIImage = CIImage(cgImage: (currentImage?.cgImage)!)
        
        
        let blend = AssetHelper.shared().blendImages(background: CIImage(cgImage: chainedFilter.cgImage!),
                                                     foreground: currentCIImage,
                                                     mask: mask)
        editedImage.image = UIImage(ciImage: blend)
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
