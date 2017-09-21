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

public let kColorFilter: String = "CIColorControls"
public let kTempFilter: String = "CITemperatureAndTint"
public let kMotionBlurFilter: String = "CIMotionBlur"

enum FilterType: Int {
    case Frame = 0, Brightness, Contrast, Temp, Fx, Blur, None
}

enum SliderType: Int {
    case Depth = 0, Focal
}

class EditViewController: UIViewController {

    //Current Assets
    fileprivate var currentAsset: PHAsset!
    
    //Filter state handling
    fileprivate var filterHelper: FilterHelper!
    
    //Outlets
    @IBOutlet fileprivate weak var editedImage: UIImageView!
    @IBOutlet fileprivate weak var depthSlider: UISlider!
    @IBOutlet fileprivate weak var focalSlider: UISlider!
    
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
        default: break

        }
    }
}

//MARK: Effect Actions
extension EditViewController {
    
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
        
        editedImage.image = filterHelper.addFiterToChain(filter: filter, value: CGFloat(value), depthValue: CGFloat(depthSlider.value))
    }

    func updateDepth(value: Float) {
        //TODO: apply filter
//        editedImage.image = filterHelper.addFiterToChain(filter: filter, value: CGFloat(value), depthValue: CGFloat(depthSlider.value))
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
