//
//  LayoutCollectionViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 11/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI

private let reuseIdentifier = "Cell"

class LayoutCollectionViewController: UICollectionViewController {

    var imagesMap = [ImageSet]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
//         self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        let layout = self.collectionView?.collectionViewLayout as? GridLayout
        layout?.fixedDivisionCount = 3
        layout?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: UICollectionViewDataSource
extension LayoutCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesMap.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0),
                                                  size: cell.frame.size))
        //Retrieve image from asset and add it to imageview
        imageView.setImage(withAsset: imagesMap[indexPath.row].image)
        cell.addSubview(imageView)
        return cell
    }

}

// MARK: UICollectionViewDelegate
extension LayoutCollectionViewController {
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
    
    
    
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
}

extension LayoutCollectionViewController {
    //Add image to the current collection, then add it to the imagesview
    func addImage(image: PHAsset, index: IndexPath) {
        
        if imagesMap.getNextIndex() >= 9 {
            return
        }
        
        imagesMap.append(ImageSet(image: image, tag: index.item))
        collectionView?.reloadData()
    }

    //Remove image from the collection then, reorder imageviews and re add views
    func removeImage(image: PHAsset, index: IndexPath) {
        
        let position = imagesMap.index(of: ImageSet(image: image, tag: index.item))
        
        Logger.log(type: .DEBUG, string: "Removing image at index \(String(describing: position))")
        imagesMap.remove(at: position!)
        collectionView?.reloadData()
    }
}

extension LayoutCollectionViewController {
    
    static func getInstance() -> LayoutCollectionViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        return story.instantiateViewController(withIdentifier: "LayoutCollectionViewController") as! LayoutCollectionViewController
    }
    
}

extension LayoutCollectionViewController: GridLayoutDelegate {
    
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        
        let sie = [1,1,1,1,2,1,1,1,1]
        
        return UInt(sie[indexPath.row])
    }
    
}
