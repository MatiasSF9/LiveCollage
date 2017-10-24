//
//  PhotoCollectionViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/19/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import TOCropViewController


class PhotoCollectionViewController: UICollectionViewController {

    fileprivate var fetchResult: PHFetchResult<PHAsset>!
    fileprivate var assetCollection: PHAssetCollection!
    
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    fileprivate var selectedAsset: PHAsset?
    
    var observer: PhotoCollectionSelectionObserver?
    
    var isEdit = false
    
    //MARK - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //only for MVP
        navigationController?.title = "Deepix"
        self.isEdit = true
        //EOMVP

        //Disables selection for edition mode
        self.collectionView?.allowsSelection = true
        self.collectionView?.allowsMultipleSelection = !isEdit
        
        initPhotoLibrary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateItemSize()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK - Private methods
    
    private func initPhotoLibrary() {
        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        // If we get here without a segue, it's because we're visible at app launch,
        // so match the behavior of segue from the default "All Photos" view.
        if fetchResult == nil {
            let allPortraitPhotos = PHFetchOptions()
            allPortraitPhotos.predicate = NSPredicate(format: "((mediaSubtype & %d) != 0)", PHAssetMediaSubtype.photoDepthEffect.rawValue)
            allPortraitPhotos.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: .image, options: allPortraitPhotos)
        }
    }
    
    private func updateItemSize() {
        
        let viewWidth = view.bounds.size.width
        
        let desiredItemWidth: CGFloat = viewWidth/4
        let columns: CGFloat = max(floor(viewWidth / desiredItemWidth), 4)
        let padding: CGFloat = 1
        let itemWidth = floor((viewWidth - (columns - 1) * padding) / columns)
        let itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = itemSize
            layout.minimumInteritemSpacing = padding
            layout.minimumLineSpacing = padding
        }
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        thumbnailSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }
    
    // MARK: UIScrollView
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        updateCachedAssets()
//    }
    
    // MARK: Asset Caching
    fileprivate func resetCachedAssets() {
        
        AssetHelper.shared().stopCaching()
        previousPreheatRect = .zero
    }

    /*
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in self.collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in self.collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    */
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
}

// MARK: UICollectionViewDataSource
extension PhotoCollectionViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult.object(at: indexPath.item)
        
        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self),
                                                            for: indexPath) as? GridViewCell
            else { fatalError("unexpected cell in collection view") }
        
        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if asset.mediaSubtypes.contains(.photoLive) {
            cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        AssetHelper.shared().getAsset(asset: asset, forSize: cell.imageView.frame.size, resultHandler: { image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                cell.thumbnailImage = image
            }
        })
        
        if cell.isSelected {
            cell.imageView.layer.borderColor = UIColor(red: 39, green: 204, blue: 255, alpha: 1).cgColor
            cell.layer.borderColor = UIColor(red: 39, green: 204, blue: 255, alpha: 1).cgColor
        } else {
            cell.imageView.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        
        return cell
    }
}

//MARK: Collection View Delegate
extension PhotoCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if isEdit {
            selectedAsset = fetchResult.object(at: indexPath.item) as PHAsset
            return presentCropViewController(selectedAsset!)
        }
        
        
        let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell
        cell?.isSelected = true
        cell?.imageView.layer.borderColor = UIColor(red: 39, green: 204, blue: 255, alpha: 1).cgColor
        cell?.layer.borderColor = UIColor(red: 39, green: 204, blue: 255, alpha: 1).cgColor
        
        observer?.didSelect(image: fetchResult.object(at: indexPath.item), index: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell
        cell?.isSelected = true
        observer?.didDeselect(image: fetchResult.object(at: indexPath.item), index: indexPath)
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension PhotoCollectionViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, !changed.isEmpty {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

//MARK - CollectionViewDelegate
extension PhotoCollectionViewController : TOCropViewControllerDelegate {
    
    fileprivate func showEditViewController(_ asset: PHAsset) {
        let controller = EditViewController.getInstance(asset: asset)
        self.navigationController?.show( controller, sender: nil)
    }
    
    fileprivate func presentCropViewController(_ asset: PHAsset) {
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        AssetHelper.shared().getAsset(asset: asset, forSize: targetSize, resultHandler: { image, _ in
            let cropViewController = TOCropViewController(image: image!)
            cropViewController.delegate = self
            self.present(cropViewController, animated: true, completion: nil)
            
        })
    }
    
    internal func cropViewController(_ cropViewController: TOCropViewController, didCropToRect cropRect: CGRect, angle: Int) {
        
        self.navigationController?.dismiss(animated: false, completion: {
            let controller = EditViewController.getInstance(asset: self.selectedAsset!, cropped: cropRect)
            self.navigationController?.show( controller, sender: nil)
        })
        
    }
    
    internal func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        
    }
    
}

extension PhotoCollectionViewController {
    
    static func getInstance() -> PhotoCollectionViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        return story.instantiateViewController(withIdentifier: "PhotoCollectionViewController") as! PhotoCollectionViewController
    }
    
}

//MARK - PhotoCollectionSelectionObserver
protocol PhotoCollectionSelectionObserver {
    
    func didSelect(image: PHAsset, index: IndexPath)
    
    func didDeselect(image: PHAsset, index: IndexPath)
    
}
