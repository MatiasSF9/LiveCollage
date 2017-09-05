//
//  PreorderedViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/12/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

class BaseLayoutController: UIViewController {
    
    var images = [UIImage]()
    
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

extension BaseLayoutController {
    
    func getContainer() -> UIView {
        return view
    }
    
    func addImage(_ image: UIImage) {
        if images.count < 9 {
            images.append(image)
            orderImages()
        }
    }
    
    private func orderImages() {
        var tempView:UIImageView? = nil
        switch images.getLastIndex() {
        case 0:
            tempView = image1
        break
        case 1:
            tempView = image2
        break
        case 2:
            tempView = image3
        break
        case 3:
            tempView = image4
        break
        case 4:
            tempView = image5
        break
        case 5:
            tempView = image6
        break
        case 6:
            tempView = image7
        break
        case 7:
            tempView = image8
        break
        case 8:
            tempView = image9
        break
        default:
            break
        }
        if tempView != nil {
            tempView!.image = images.getLastItem() as! UIImage
        }
        
    }
    
}

extension Array {
    
    func getLastIndex() -> Int {
        return count - 1
    }
    
    func getLastItem() -> Any {
        return self[getLastIndex()]
    }
}
