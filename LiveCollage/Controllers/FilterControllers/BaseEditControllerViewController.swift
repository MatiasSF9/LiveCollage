//
//  BaseEditControllerViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 13/11/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI


class BaseEditControllerViewController: UIViewController {

    //MARK: Properties
    internal var currentAsset: PHAsset!
    internal var currentImage: CIImage?
    internal var croppedRect: CGRect?
    internal var originalSize: CGRect?
    internal var imageOrientation: UIImageOrientation?
    internal var currentType: FilterSwitch = .Background
    
    //Filter state handling
    internal var filterHelper: FilterHelper!
    
    //Disparity Image
    internal var disparityImage: CIImage?
    
    var depthEnabled: Bool = false

    //Temp Image
    var tempImage:UIImage?
    var displayOriginal:Bool = false
    
    //MARK: Outlets
    @IBOutlet internal weak var lblDepth: UILabel!
    @IBOutlet internal weak var imageView: UIImageView!
    @IBOutlet internal weak var depthSlider: UISlider!
    @IBOutlet internal weak var segmentedControl: UISegmentedControl!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //Disable depth by default
        lblDepth.isHidden = true
        lblDepth.layer.masksToBounds = true
        lblDepth.layer.cornerRadius = 4.0
        depthSlider.isEnabled = false
        
        //Get Image Data Async
        if currentAsset != nil {
            getImageFromAsset()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Assets Handling
    
    func getImageFromAsset() {
        AssetHelper.shared().getImageData(asset: currentAsset) { [weak self] imageData in
            
            if imageData.info == nil  || imageData.data == nil {
                return
            }
            
            self?.currentImage = CIImage(data: imageData.data!)
            //Rotation
            self?.imageOrientation = imageData.orientation
            self?.currentImage = self?.currentImage?.rotateImage(orientation: (self?.imageOrientation)!)
            
            if self?.currentImage != nil {
                self?.displayImage(image: UIImage(ciImage: (self?.currentImage!)!))
                self?.filterHelper = FilterHelper(editedImage: (self?.currentImage!)!, frame: (self?.imageView.frame)!)
            }
            
            //Check if image has depth info
            if AssetHelper.shared().hasDepthInformation(info: imageData.info!) {
                self?.enableDepth(imageData: imageData.data!)
            } else {
                Logger.VERBOSE(message: "No depth information 💔")
            }
        }
    }
    
    internal func displayImage(image: UIImage) {
        if croppedRect != nil {
            imageView.image = image.croppedImage(withFrame: croppedRect!, angle: 0, circularClip: false)
        } else {
            imageView.image = image
        }
    }
    
    internal func enableDepth(imageData: Data) {
        
        disparityImage = AssetHelper.shared().getDisparityImage(imageData: imageData)
        disparityImage = disparityImage?.rotateImage(orientation: (self.imageOrientation)!)
        
        guard let size = currentImage?.extent.size else {
            return
        }
        
        guard let dispSize = disparityImage?.extent.size else {
            return
        }
        
        let scaleX = Float(size.width) / Float(dispSize.width)
        let scaleY = Float(size.height) / Float(dispSize.height)
        
        //TODO: remove hardcoded scale
        let transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        
        disparityImage = disparityImage?.transformed(by: transform)
        if disparityImage != nil {
            
            //Uncomment to display disparity image
            //editedImage.image = UIImage(ciImage: disparityImage!)
            
            filterHelper.setDisparity(image: disparityImage!)
            depthEnabled = true
            lblDepth.isHidden = false
            
            Logger.VERBOSE(message: "Disparity image obtained!! 💕")
        } else {
            Logger.VERBOSE(message: "No disparity image available!! 💔")
        }
    }
    
    //Gets Min and Max gray values for a given rect
    //USE: pass the touch rect to get min and max to be applied in disparity image
    func minMax(from rect: CGRect) -> (min: Float, max: Float) {
        let height = imageView.image!.size.height
        let width = imageView.image!.size.width
        let rect = CGRect(x: 0, y: CGFloat(depthSlider.value) * height, width: width, height: height * 1)
        let minMax = AssetHelper.shared().sampleDiparity(disparityImage: disparityImage!, rect: rect)
        return minMax
    }
    
    //MARK: Convenience methods for Gestures
    func handleForceTouch() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        if !displayOriginal {
            showOriginal(show: true)
        }
    }
    
    func handleTouchMovement(to rect: CGPoint) {
        
    }
    
    //Works as a Peek of the original unedited image
    func showOriginal(show: Bool) {
        displayOriginal = show
        if displayOriginal {
            displayImage(image: UIImage(ciImage: currentImage!))
            Logger.VERBOSE(message: "Displaying Original")
        } else if(tempImage != nil) {
            displayImage(image: tempImage!)
            Logger.VERBOSE(message: "Displaying Edited")
        }
    }
    
    //Updates the image displayed by applying the filter chain
    func updateRender() {
        
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
}

extension BaseEditControllerViewController: UIGestureRecognizerDelegate {
    
    //MARK: Gestures Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        Logger.VERBOSE(message: "Touches Began")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        Logger.VERBOSE(message: "Touches Ended")
        showOriginal(show: false)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        Logger.VERBOSE(message: "Touches Moved")
        
        guard let touch = touches.first else {
            return
        }
        if touch.force > 2.0 {
            handleForceTouch()
        } else {
            handleTouchMovement(to: touch.location(in: imageView))
        }
    }
}
