//
//  CollageView.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/13/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

class CollageView: UIView {
    
    fileprivate var images = [UIImage]()
    
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    @IBOutlet weak var image5: UIImageView!
    @IBOutlet weak var image6: UIImageView!
    @IBOutlet weak var image7: UIImageView!
    @IBOutlet weak var image8: UIImageView!
    @IBOutlet weak var image9: UIImageView!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */


}

extension CollageView {
    
    func addImage(_ image: UIImage) {
        if images.count < 9 {
            images.append(image)
            orderImages()
        }
    }
    
    private func orderImages() {
        let index = images.count
        
        switch index {
        case 1:
            image1.image = images[index]
            break
        case 2:
            image2.image = images[index]
            break
        case 3:
            image3.image = images[index]
            break
        case 4:
            image4.image = images[index]
            break
        case 5:
            image5.image = images[index]
            break
        case 6:
            image6.image = images[index]
            break
        case 7:
            image7.image = images[index]
            break
        case 8:
            image8.image = images[index]
            break
        case 9:
            image8.image = images[index]
            break
        default:
            break
        }
        
    }
    
}
