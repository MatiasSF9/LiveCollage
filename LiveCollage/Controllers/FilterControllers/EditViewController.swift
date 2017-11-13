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

class EditViewController: BaseEditControllerViewController {

    //Outlets
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet fileprivate weak var focalSlider: UISlider!
    @IBOutlet fileprivate weak var lblDepthValue: UILabel!
    @IBOutlet fileprivate weak var lblFocalValue: UILabel!
    
    //Filters Setup
    fileprivate var filterControls: CIFilter?
    fileprivate var filterTempAndTint: CIFilter?
    fileprivate var filterBlur: CIFilter?
    fileprivate var filterFX: HB2Filter?
    fileprivate var filterCandy: CandyFilter?
    fileprivate var currentFilter: FilterType = .None
    
    override func viewDidLoad() {
        super.viewDidLoad()
        focalSlider.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func enableDepth(imageData: Data) {
        super.enableDepth(imageData: imageData)
        if currentFilter != .None {
            depthSlider.isEnabled = true
        }
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
            guard let state = filterHelper.getFilter(filterName: "HB2Filter", filterSwitch: currentType) else {
                filterFX = HB2Filter()
                return
            }
            filterFX = state.filter as! HB2Filter
            restoreSliders(focal: 1, depth: Float(depth), slope: 1)
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
                filterCandy = CandyFilter()
                return
            }
            filterCandy = state.filter as! CandyFilter
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

    override func handleTouchMovement(to rect: CGPoint) {
        super.handleTouchMovement(to: rect)
        
        let size = imageView.frame.size
        let bias = Float(rect.y) / Float(size.height)
        
        depthSlider.value = -(bias * 4 - 2)
        lblDepthValue.text = "\(depthSlider.value)"
        updateFilter()
        updateRender()
    }
    
}

//MARK: Effect Actions
extension EditViewController {
    
    private func updateFilter() {
        var filter: CIFilter?
        let value = focalSlider.value
        switch currentFilter {
        case .Frame:
            filter = filterFX
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
            filter = filterCandy
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

