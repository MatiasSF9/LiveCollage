//
//  PreorderedViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/12/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import Photos

struct ImageSet: Equatable {
    
    var image: PHAsset
    var tag: Int
    
    static func ==(lhs: ImageSet, rhs: ImageSet) -> Bool {
        return lhs.tag == rhs.tag
    }
    
}

class PreorderedViewController: UIViewController {
    
    var imagesMap = [ImageSet]()
    
    @IBOutlet fileprivate weak var image1: UIImageView!
    @IBOutlet fileprivate weak var image2: UIImageView!
    @IBOutlet fileprivate weak var image3: UIImageView!
    @IBOutlet fileprivate weak var image4: UIImageView!
    @IBOutlet fileprivate weak var image5: UIImageView!
    @IBOutlet fileprivate weak var image6: UIImageView!
    @IBOutlet fileprivate weak var image7: UIImageView!
    @IBOutlet fileprivate weak var image8: UIImageView!
    @IBOutlet fileprivate weak var image9: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension PreorderedViewController {
    
    //Add image to the current collection, then add it to the imagesview
    func addImage(image: PHAsset, index: IndexPath) {
        
        if imagesMap.getNextIndex() >= 9 {
            return
        }
        
        imagesMap.append(ImageSet(image: image, tag: index.item))
        reloadImages()
    }
    
    //Add all available images to imageviews
    private func reloadImages() {
        var lastIndex = 0
        
        Logger.log(type: .DEBUG, string: "Reload images begin")
        for (index, value) in imagesMap.enumerated() {
            let container = getView(index: index)!
            //Retrieve image from asset and add it to imageview
            container.setImage(withAsset: value.image)
            lastIndex = index + 1
        }
        
        if lastIndex > 8 { //No more slots to add
            return
        }
        
        for index in lastIndex...8 {
            let container = getView(index: index)!
            container.image = nil
            Logger.log(type: .DEBUG, string: "Removed image at index \(index)")
        }
        Logger.log(type: .DEBUG, string: "Reload images end")
    }
    
    //Remove image from the collection then, reorder imageviews and re add views
    func removeImage(image: PHAsset, index: IndexPath) {
        
        let position = imagesMap.index(of: ImageSet(image: image, tag: index.item))
        
        Logger.log(type: .DEBUG, string: "Removing image at index \(String(describing: position))")
        imagesMap.remove(at: position!)
        reloadImages()
    }
    
    private func getView(index: Int) -> UIImageView? {
        Logger.log(type: .DEBUG, string: "Getting image view at Index \(index)")
        switch index {
        case 0:
            return image1
        case 1:
            return image2
        case 2:
            return image3
        case 3:
            return image4
        case 4:
            return image5
        case 5:
            return image6
        case 6:
            return image7
        case 7:
            return image8
        case 8:
            return image9
        default:
            Logger.log(type: .DEBUG, string: "No image view at Index \(index)")
           break
        }
        return nil
    }
    
}

extension PreorderedViewController {
    static func getInstance() -> PreorderedViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        return story.instantiateViewController(withIdentifier: "PreorderedViewController") as! PreorderedViewController
    }
}

extension Array {
    
    func getNextIndex() -> Int {
        return self.count
    }
    
    func getLastIndex() -> Int {
        return count - 1
    }
    
    func getLastItem() -> Any {
        return self[getLastIndex()]
    }
}
