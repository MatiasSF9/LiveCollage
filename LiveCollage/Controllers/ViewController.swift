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

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet fileprivate weak var collection: UICollectionView!
    @IBOutlet weak var pickerContainer: UIView!
    @IBOutlet weak var collageContainer: UIView!
    var picker: UIImagePickerController!
    var collageController: PreorderedViewController!
    
    fileprivate var imagesArray = [PHLivePhoto]()
    //MARK: Lifecycle Methods
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let story = UIStoryboard(name: "Main", bundle: nil)
        collageController = story.instantiateViewController(withIdentifier: "PreorderedViewController") as! PreorderedViewController
        
        picker = UIImagePickerController()
        
        iniciateLayoutView()
        openLibrary()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func iniciateLayoutView() {
        
        self.addChildViewController(collageController)
        collageController.view.frame = collageContainer.frame
        collageContainer.addSubview(collageController.view)
        collageController.didMove(toParentViewController: self)
    }

    //MARK: Private Methods
    func openLibrary() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        
        guard let mediaTypes = UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.photoLibrary) else {
            return
        }
        for type in mediaTypes  {
            if type == kUTTypeLivePhoto as String || type == kUTTypeImage as String{
                
            }
        }
        
        self.addChildViewController(picker)
        picker.modalPresentationStyle = .currentContext
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String , kUTTypeLivePhoto as String]
        picker.delegate = self
        
        let pickerView = picker.view
        pickerView?.frame.size = pickerContainer.frame.size
        pickerContainer.addSubview(picker.view)
        picker.didMove(toParentViewController: self)
    }
    
    //MARK: Actions
    @IBAction func onLongPress(_ sender: UILongPressGestureRecognizer) {
        openLibrary()
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        openLibrary() 
    }

}

extension ViewController: UIImagePickerControllerDelegate {
    
    //MARK: Picker Controller Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let type = info[UIImagePickerControllerMediaType] as! String
        
        if type == "com.apple.live-photo" {
            let tempImage = info [UIImagePickerControllerLivePhoto] as! PHLivePhoto
//            imagesArray.append(tempImage)
            
        } else {
            let tempImage = info [UIImagePickerControllerOriginalImage] as! UIImage
            collageController.addImage(tempImage)
        }
//        collection.reloadData()
        picker.popViewController(animated: true)
        openLibrary()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: {})
    }
}

extension ViewController: UICollectionViewDelegate {
    //MARK: Collection Delegate

}

extension ViewController: UICollectionViewDataSource {
    
    //MARK: Collection Data Source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var view: BaseCollectionCell
        
        //AddCell
        if(indexPath.row == imagesArray.count) {
            view = collectionView.dequeueReusableCell(withReuseIdentifier: "AddImageCell", for: indexPath) as! AddImageCell
        }
            //ImageCell
        else {
            view = collectionView.dequeueReusableCell(withReuseIdentifier: "LiveImageCell", for: indexPath) as! LiveImageCell
            
            (view as? LiveImageCell)?.setPhoto(imagesArray[indexPath.row])
            (view as? LiveImageCell)?.play()
        }
        
        return view
        
    }

}
