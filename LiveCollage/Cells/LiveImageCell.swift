//
//  LiveImageCell.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 16/04/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI

class LiveImageCell: BaseCollectionCell, PHLivePhotoViewDelegate {
    
    @IBOutlet weak var containerView: UIView!
    let photoView =  PHLivePhotoView()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        photoView.delegate = self
        photoView.frame = containerView.bounds
        photoView.addConstraints(containerView.constraints)
        self.addSubview(photoView)
        self.bringSubview(toFront: photoView)
    }
    
    func setPhoto(_ photo: PHLivePhoto) {
        
        photoView.livePhoto = photo
        
    }

    func play() {
        photoView.startPlayback(with: .full)
    }
    
    //MARK: Live Photo Delegate
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        play()
    }
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        
    }
    
}
