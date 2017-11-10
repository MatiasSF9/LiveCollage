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
import AudioToolbox

public let kColorFilter: String = "CIColorControls"
public let kTempFilter: String = "CITemperatureAndTint"
public let kMotionBlurFilter: String = "CIGaussianBlur"

enum FilterType: Int {
    case Frame = 0, Brightness, Contrast, Temp, Fx, Blur, None
}

enum SliderType: Int {
    case Depth = 0, Focal
}

class EditViewController: UIViewController {

    //Current Assets
    fileprivate var currentAsset: PHAsset!
    fileprivate var croppedRect: CGRect?
    fileprivate var originalSize: CGRect?
    fileprivate var imageOrientation: UIImageOrientation?
    fileprivate var currentType: FilterSwitch = .Background
    
    //Current Image
    fileprivate var currentImage: CIImage?
    
    //Filter state handling
    fileprivate var filterHelper: FilterHelper!
    
    //Disparity Image
    fileprivate var disparityImage: CIImage?
    
    //Outlets
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet fileprivate weak var editedImage: UIImageView!
    @IBOutlet fileprivate weak var depthSlider: UISlider!
    @IBOutlet fileprivate weak var focalSlider: UISlider!
    @IBOutlet fileprivate weak var depthLabel: UILabel!
    @IBOutlet fileprivate weak var lblDepthValue: UILabel!
    @IBOutlet fileprivate weak var lblFocalValue: UILabel!
    @IBOutlet fileprivate weak var segmentedControl: UISegmentedControl!
    
    //Filters Setup
    fileprivate let context = CIContext()
    fileprivate var filterControls: CIFilter?
    fileprivate var filterTempAndTint: CIFilter?
    fileprivate var filterBlur: CIFilter?
    fileprivate var filterFX: CandyFilter?
    
    fileprivate var currentFilter: FilterType = .None
    
    var depthEnabled: Bool = false
    
    //Temp Image
    var tempImage:UIImage?
    var displayOriginal:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Disable depth by default
        depthLabel.isHidden = true
        depthLabel.layer.masksToBounds = true
        depthLabel.layer.cornerRadius = 4.0
        depthSlider.isEnabled = false
        focalSlider.isEnabled = false
        
        //Get Image Data Async
        if currentAsset != nil {
            getImageFromAsset()
        }
        
    }

    private func getImageFromAsset() {
        AssetHelper.shared().getImageData(asset: currentAsset) { [weak self] imageData in
            
            if imageData.info == nil  || imageData.data == nil {
                return
            }
            
            self?.currentImage = CIImage(data: imageData.data!)
            
            //TODO: ROTATE IMAGE
            self?.imageOrientation = imageData.orientation
            self?.currentImage = self?.currentImage?.rotateImage(orientation: (self?.imageOrientation)!)
            
            if self?.currentImage != nil {
                
                self?.displayImage(image: UIImage(ciImage: (self?.currentImage!)!))
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
        
        for button in buttons {
            if button.tag != sender.tag {
                button.isSelected = false
            } else {
                button.isSelected = true
            }
        }
        
        focalSlider.isEnabled = true
        if depthEnabled {
            depthSlider.isEnabled = true
        }
        
        currentFilter = FilterType(rawValue: sender.tag)!
        restoreFilter(filterType: currentFilter)
        
    }
    
    private func restoreFilter(filterType: FilterType) {
        
        let depth = filterHelper.getDepth(filterSwitch: currentType)
        
        switch filterType {
        case .Frame:
            break
        case .Brightness:
            focalSlider.minimumValue = -0.1
            focalSlider.maximumValue = 0.1
            guard let state = filterHelper.getFilter(filterName: kColorFilter, filterSwitch: currentType) else {
                filterControls = CIFilter(name: kColorFilter)!
                return
            }
            filterControls = state.filter
            let focal = state.filter.value(forKey: kCIInputBrightnessKey) as! Float
            restoreSliders(focal: focal, depth: Float(depth), slope: 1.0)
            break
        case .Contrast:
            focalSlider.minimumValue = 0.9
            focalSlider.maximumValue = 1.1
            guard let state = filterHelper.getFilter(filterName: kColorFilter, filterSwitch: currentType) else {
                filterControls = CIFilter(name: kColorFilter)!
                return
            }
            filterControls = state.filter
            let focal = state.filter.value(forKey: kCIInputContrastKey) as! Float
            restoreSliders(focal: focal, depth: Float(depth), slope: 1.0)
            break
        case .Temp:
            focalSlider.minimumValue = 2000
            focalSlider.maximumValue = 10000
            guard let state = filterHelper.getFilter(filterName: kTempFilter, filterSwitch: currentType) else {
                filterTempAndTint = CIFilter(name: kTempFilter)!
                return
            }
            filterTempAndTint = state.filter
            let focal = state.filter.value(forKey: "inputNeutral") as! CIVector
            restoreSliders(focal: Float(focal.x), depth: Float(depth), slope: 1.0)
            break
        case .Fx:
            guard let state = filterHelper.getFilter(filterName: "CandyFilter", filterSwitch: currentType) else {
                filterFX = CandyFilter()
                return
            }
            filterFX = state.filter as! CandyFilter
            restoreSliders(focal: 1, depth: Float(depth), slope: 1)
            break
        case .Blur:
            guard let state = filterHelper.getFilter(filterName: kMotionBlurFilter, filterSwitch: currentType) else {
                filterBlur = CIFilter(name: kMotionBlurFilter)
                return
            }
            filterBlur = state.filter
            let vector = state.filter.value(forKey: "inputRadius") as! Float
            restoreSliders(focal: Float(vector), depth: Float(depth), slope: 1.0)
            break
        case .None: break
        default: break
        }
        
    }
    
    private func restoreSliders(focal: Float, depth: Float, slope: Float) {
        focalSlider.value = focal
        depthSlider.value = depth
    }
    
    @IBAction func onValueChange(_ sender: UISlider) {
        
        switch sender.tag {
        case SliderType.Depth.rawValue:
            lblDepthValue.text = "\(depthSlider.value)"
            break
        case SliderType.Focal.rawValue:
            lblFocalValue.text = "\(focalSlider.value)"
            break
        default:
            break
        }

        updateFilter()
        updateRender()
    }
  
    @IBAction func onSegmentChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case FilterSwitch.Background.rawValue:
            currentType = FilterSwitch.Background
            break
        case FilterSwitch.Foreground.rawValue:
            currentType = FilterSwitch.Foreground
            break;
        default:
            currentType = FilterSwitch.Background
        }
        
        restoreFilter(filterType: currentFilter)
//        updateFilter()
        updateRender()
    }

}

//MARK: Effect Actions
extension EditViewController {
    
    private func enableDepth(imageData: Data) {
        
        disparityImage = AssetHelper.shared().getDisparityImage(imageData: imageData)
        
        guard let size = currentImage?.extent.size else {
            return
        }
        
        guard let dispSize = disparityImage?.extent.size else {
            return
        }
        
        let scaleX = Float(size.width) / Float(dispSize.width)
        let scaleY = Float(size.height) / Float(dispSize.height)
        let transform = CGAffineTransform(scaleX: CGFloat(5.25), y: CGFloat(5.25))
        disparityImage = disparityImage?.rotateImage(orientation: (self.imageOrientation)!)
        disparityImage = disparityImage?.transformed(by: transform)
        if disparityImage != nil {
            
            //Uncomment to display disparity image
            //editedImage.image = UIImage(ciImage: disparityImage!)
            
            filterHelper.setDisparity(image: disparityImage!)
            depthEnabled = true
            depthLabel.isHidden = false
            
            if currentFilter != .None {
                depthSlider.isEnabled = true
            }
            
            Logger.VERBOSE(message: "Disparity image obtained!! 💕")
        }
    }
    
    private func updateFilter() {
        var filter: CIFilter?
        let value = focalSlider.value
        switch currentFilter {
        case .Frame:
            //TODO: crop
            break
        case .Brightness:
            filterControls?.setValue(value, forKey: kCIInputBrightnessKey)
            filter = filterControls
            break
        case .Contrast:
            filterControls?.setValue(value, forKey: kCIInputContrastKey)
            filter = filterControls
            break
        case .Temp:
            let scale: CGFloat = CGFloat(value)
            let vector = CIVector(x: scale, y: 0)
            filterTempAndTint?.setValue(vector, forKey: "inputNeutral")
            filterTempAndTint?.setValue(CIVector(x: 6500, y:0), forKey: "inputTargetNeutral")
            filter = filterTempAndTint
            break
        case .Fx:
            filter = filterFX
            break
        case .Blur:
            filterBlur?.setValue(10.0, forKey: "inputRadius")
            filter = filterBlur
            break
        default:
            break
        }

        if filter == nil {
            return
        }
        filterHelper.addFiterToChain(filter: filter!,  value: CGFloat(focalSlider.value),
                                     depthEnabled: disparityImage != nil,
                                     depth: CGFloat(depthSlider.value), slope: 1,
                                     filterSwitch: currentType)

    }

    //Updates the image displayed by applying the filter chain
    private func updateRender() {
        
        if currentImage == nil {
            return
        }

        //UNcomment to display mask
//        let mask = AssetHelper.shared().getBlendMask(disparityImage: disparityImage!,
//                                                     slope:  1,
//                                                     bias: CGFloat(depthSlider.value),
//                                                     inverted: currentType == .Foreground)
//        editedImage.image = UIImage(ciImage: mask)
//        return
        
        let height = editedImage.image!.size.height
        let width = editedImage.image!.size.width
//        let rect = CGRect(x: 0, y: CGFloat(depthSlider.value) * height, width: width, height: height * 1)
//        let minMax = AssetHelper.shared().sampleDiparity(disparityImage: disparityImage!, rect: rect)
        if disparityImage == nil {
            let chained = filterHelper.applyChain()
            displayImage(image: chained)
            tempImage = chained
        } else {
            let chained = filterHelper.applyDepthChain()
            tempImage = chained
            displayImage(image: chained)
        }
        
    }
    
    private func displayImage(image: UIImage) {
        if croppedRect != nil {
            editedImage.image = image.croppedImage(withFrame: croppedRect!, angle: 0, circularClip: false)
        } else {
            editedImage.image = image
        }
    }
}

//MARK: Instance Factory
extension EditViewController {
    
    static func getInstance(asset: PHAsset) -> EditViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        let controller = story.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        controller.currentAsset = asset
        return controller
    }
    
    static func getInstance(asset: PHAsset, cropped: CGRect) -> EditViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        let controller = story.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        controller.currentAsset = asset
        controller.croppedRect = cropped
        return controller
    }
}


extension EditViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        Logger.VERBOSE(message: "Touches Began")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        Logger.VERBOSE(message: "Displaying Edited")
        if tempImage != nil {
            displayImage(image: tempImage!)
        }
        displayOriginal = false
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            if touch.force > 2.0 && !displayOriginal {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                displayOriginal = true
                displayImage(image: UIImage(ciImage: currentImage!))
                Logger.VERBOSE(message: "Displaying Original")
            } else {
                let location = touch.location(in: editedImage)
                let size = editedImage.frame.size
                let bias = Float(location.y) / Float(size.height)
                
                depthSlider.value = -(bias * 4 - 2)
                lblDepthValue.text = "\(depthSlider.value)"
                updateFilter()
                updateRender()
            }
            
        }
    }
    
}
