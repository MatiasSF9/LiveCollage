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
    
    var collageController: LayoutCollectionViewController!
    var photosController: PhotoCollectionViewController!
    
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
        
        collageController = LayoutCollectionViewController.getInstance()
        add(controller: collageController, toContainerView: collageContainer)
        
        photosController = PhotoCollectionViewController.getInstance()
        add(controller: photosController, toContainerView: photosContainer)
        photosController.observer = self
    }
    
    fileprivate func add(controller: UIViewController, toContainerView containerView: UIView) {
        self.addChildViewController(controller)
        controller.view.frame.size = containerView.frame.size
        containerView.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
    }
    
    fileprivate func add(controller: UICollectionViewController, toContainerView containerView: UIView) {
        self.addChildViewController(controller)
        controller.view.frame.size = containerView.frame.size
        //        controller.collectionView?.frame = controller.view.frame
        containerView.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
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
