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
public let kMotionBlurFilter: String = "CIBoxBlur"

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
    fileprivate var currentImage: CIImage?
    
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
    
    var depthEnabled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Disable depth by default
        depthLabel.isHidden = true
        depthSlider.isEnabled = false
        slopeSlider.isEnabled = false
        focalSlider.isEnabled = false
        
        //Get Image Data Async
        AssetHelper.shared().getImageData(asset: currentAsset) { [weak self] imageData in
            
            if imageData.info == nil  || imageData.data == nil {
                return
            }
            
            
            self?.currentImage = CIImage(data: imageData.data!)
//            let tranform = self?.currentImage?.orientationTransform(for: .up)
//            self?.currentImage = self?.currentImage?.transformed(by: tranform!)
            
            if self?.currentImage != nil {
                self?.editedImage.image = UIImage(ciImage: (self?.currentImage!)!)
                self?.filterHelper = FilterHelper(editedImage: (self?.currentImage!)!, frame: (self?.editedImage.frame)!)
            }
            
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
        
        focalSlider.isEnabled = true
        
        if depthEnabled {
            depthSlider.isEnabled = true
            slopeSlider.isEnabled = true
        }
        
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
            let vector = state.filter.value(forKey: "inputRadius") as! NSNumber
            focalSlider.value = Float(vector.floatValue / 200.0)
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
        
        disparityImage = AssetHelper.shared().getDisparityImage(imageData: imageData)
        guard let size = currentImage?.extent.size else {
            return
        }
        
        guard let dispSize = disparityImage?.extent.size else {
            return
        }
        
        
        let scaleX = Float((size.width)) / Float((dispSize.width))
        let scaley = Float(size.height) / Float(dispSize.height)
        let transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaley))
        disparityImage = disparityImage?.transformed(by: transform)
        if disparityImage != nil {
            
            //Uncomment to display disparity image
            //editedImage.image = UIImage(ciImage: disparityImage!)
            
            filterHelper.setDisparity(image: disparityImage!)
            depthEnabled = true
            depthLabel.isHidden = false
            
            if currentFilter != .None {
                depthSlider.isEnabled = true
                slopeSlider.isEnabled = true
            }
            
//            let mask = AssetHelper.shared().getBlendMask(disparityImage: disparityImage!, slope: 0.3, bias: 0.3)
//            self.editedImage.image = UIImage(ciImage: mask)
            
            Logger.VERBOSE(message: "Disparity image obtained!! 💕")
        }
    }
    
    private func updateFilter(value: Float) -> CIFilter {
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
            filterBlur.setValue(value * 200.0, forKey: "inputRadius")
            filter = filterControls
            break
        default:
            return filter
        }
        
        return filter
    }
    
    func updateValues(value: Float) {
        let filter = updateFilter(value: value)
        _ = filterHelper.addFiterToChain(filter: filter, value: CGFloat(value), depthEnabled: disparityImage != nil, depth: CGFloat(depthSlider.value), slope: CGFloat(slopeSlider.value))
        updateRender()
    }

    func updateDepth(value: Float) {
        let filter = updateFilter(value: focalSlider.value)
        _ = filterHelper.addFiterToChain(filter: filter, value: CGFloat(focalSlider.value), depthEnabled: disparityImage != nil, depth: CGFloat(value), slope: CGFloat(slopeSlider.value))
        updateRender()
    }
    
    func updateSlope(value: Float) {
        let filter = updateFilter(value: focalSlider.value)
        _ = filterHelper.addFiterToChain(filter: filter, value: CGFloat(focalSlider.value), depthEnabled: disparityImage != nil, depth: CGFloat(depthSlider.value), slope: CGFloat(slopeSlider.value))
        updateRender()
    }
    
    private func updateRender() {
        
        
//        let mask = AssetHelper.shared().getBlendMask(disparityImage: disparityImage!, slope: CGFloat(slopeSlider.value), bias: CGFloat(depthSlider.value))
//        self.editedImage.image = UIImage(ciImage: mask)
//        return
        
        if currentImage == nil {
            return
        }
        
        let scale = CGFloat(slopeSlider.value)
        let height = editedImage.image!.size.height
        let width = editedImage.image!.size.width
        let minMax = AssetHelper.shared().sampleDiparity(disparityImage: disparityImage!,
                                                         rect: CGRect(x: 0, y: CGFloat(depthSlider.value) * height,
                                                                      width: width ,
                                                                      height: height * scale))
        if disparityImage == nil {
            let chained = filterHelper.applyChain()
            editedImage.image = chained
        } else {
            let chained = filterHelper.applyDepthChain()
            editedImage.image = chained
        }
        
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
