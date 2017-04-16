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

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet private weak var collection: UICollectionView!
    
    private var imagesArray = [PHLivePhoto]()
    
    
    //MARK: Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collection.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: Private Methods
    
    func openLibrary() {
        let picker = UIImagePickerController()
        picker.modalPresentationStyle = UIModalPresentationStyle.currentContext
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String , kUTTypeLivePhoto as String]
        picker.delegate = self
        self.present(picker, animated: true) {
            
        }
        
    }
    
    
    //MARK: Actions
    
    @IBAction func onLongPress(_ sender: UILongPressGestureRecognizer) {
        openLibrary()
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        openLibrary() 
    }
    

    //MARK: Collection Delegate
    
    
    
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
    
    //MARK: Picker Controller Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
        
        let tempImage: PHLivePhoto = info [UIImagePickerControllerLivePhoto] as! PHLivePhoto
        imagesArray.append(tempImage)
        
        self.dismiss(animated: true, completion: {})
        collection.reloadData()
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: {})
    }
}

