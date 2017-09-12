//
//  EditViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 12/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI

class EditViewController: UIViewController {

    fileprivate var currentImage: PHAsset!
    
    @IBOutlet weak var editedImage: UIImageView!
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var depthSwitch: UISwitch!
    @IBOutlet weak var focalSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editedImage.setImage(withAsset: currentImage)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCrop(_ sender: UIButton) {
    }
    
    @IBAction func onTemp(_ sender: UIButton) {
    }
    
    @IBAction func onContrast(_ sender: UIButton) {
    }
    
    @IBAction func onDepthToggle(_ sender: UISwitch) {
    }
    
    @IBAction func onFocalToggle(_ sender: UISwitch) {
    }
}

//MARK: Effect Actions
extension EditViewController {
    
    
    
}

//Instance Factory
extension EditViewController {
    
    static func getInstance(asset: PHAsset) -> EditViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        let controller = story.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        controller.currentImage = asset
        return controller
    }
    
}
