//
//  ViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 16/04/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import MobileCoreServices
import PhotosUI

class ViewController: UIViewController {

    @IBOutlet weak var photosContainer: UIView!
    @IBOutlet weak var collageContainer: UIView!
    
    var photosController: PhotoCollectionViewController!
    var collageController: PreorderedViewController!
    
    fileprivate var imagesArray = [PHLivePhoto]()
    //MARK: Lifecycle Methods
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        iniciateLayoutView()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func iniciateLayoutView() {
        
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        collageController = story.instantiateViewController(withIdentifier: "PreorderedViewController") as! PreorderedViewController
        self.addChildViewController(collageController)
        collageController.view.frame = collageContainer.frame
        collageContainer.addSubview(collageController.view)
        collageController.didMove(toParentViewController: self)
        
        photosController = story.instantiateViewController(withIdentifier: "PhotoCollectionViewController") as! PhotoCollectionViewController
        self.addChildViewController(photosController)
        photosController.view.frame.size = photosContainer.frame.size
        photosController.collectionView?.frame = photosController.view.frame
        photosContainer.addSubview(photosController.view)
        photosController.didMove(toParentViewController: self)
        
        photosController.observer = self
    }

}

extension ViewController: PhotoCollectionSelectionObserver {
    
    func didSelect(image: PHAsset, index: IndexPath) {
        collageController.addImage(image: image, index: index)
    }
    
    func didDeselect(image: PHAsset, index: IndexPath) {
        collageController.removeImage(image: image, index: index)
    }
    
    
}
