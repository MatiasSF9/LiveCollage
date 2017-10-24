//
//  CIImage+Utils.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 18/10/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

extension CIImage {

    func rotateImage(orientation: UIImageOrientation) -> CIImage {
        
        var angle = CGImagePropertyOrientation.up
        
        switch orientation {
        case .up, .upMirrored:
            angle = CGImagePropertyOrientation.up
            break
        case .down, .downMirrored:
            angle = CGImagePropertyOrientation.down
            break
        case .right, .rightMirrored:
            angle = CGImagePropertyOrientation.right
            break
        case .left,.leftMirrored:
            angle = CGImagePropertyOrientation.left
            break
        }
        let tranform = self.orientationTransform(for: angle)
        return self.transformed(by: tranform)
    }

    func cropToRect(rect: CGRect) -> CIImage? {
        let vector = CIVector(x: rect.origin.x, y: rect.origin.y, z: rect.size.width, w: rect.size.height)
        let filter = CIFilter(name: "CICrop")
        filter?.setValue(self, forKey: "inputImage")
        filter?.setValue(vector, forKey: "inputRectangle")
        return filter?.outputImage
    }
}
