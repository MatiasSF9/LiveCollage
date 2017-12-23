//
//  FilterViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 13/11/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit
import PhotosUI

class FilterViewController: BaseEditControllerViewController {

    
    //MARK: Outlets
    @IBOutlet weak var filterCollection: UICollectionView!
    
    let filters = ["HB2Filter", "CandyFilter", "DarkSummer", "Sepia", "Chrome", "Fade", "B&W"]
    var backgroundIndex: Int = -1
    var foregroundIndex: Int = -1
    var fImages = [UIImage]()
    
    var currentFilter:CIFilter? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for name in filters {
            guard let filter = filter(name: name) else {
                fImages.append(UIImage(ciImage: currentImage!))
                return
            }
            let tmp = UIImage(ciImage: filter.outputImage!)
            fImages.append(tmp)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    @IBAction func onSegmentChange(_ sender: Any) {
        var row = currentSwitch() == .Background ? backgroundIndex : foregroundIndex
        self.filterCollection.reloadData()
    }
    
    @IBAction func onSliderValueChange(_ sender: UISlider) {
        
        updateFilter()
        updateRender()
    }
    
    private func currentSwitch() ->FilterSwitch {
        guard let state = FilterSwitch(rawValue: segmentedControl.selectedSegmentIndex) else {
            return FilterSwitch.Background
        }
        return state
    }
    
    func filter(name: String) -> CIFilter? {
        var filter:CIFilter?
        if name == "HB2Filter" {
            filter = HB2Filter()
        } else if name == "CandyFilter" {
            filter = CandyFilter()
        }
        else if name == "DarkSummer" {
            filter = DarkSummer()
        }
        else if name == "Sepia" {
            filter = CIFilter(name: "CISepiaTone")
        }
        else if name == "Chrome" {
            filter = CIFilter(name: "CIPhotoEffectChrome")
        }
        else if name == "Fade" {
            filter = CIFilter(name: "CIPhotoEffectFade")
        }
        else if name == "Noir" {
            filter = CIFilter(name: "CIPhotoEffectNoir")
        }
        else if name == "B&W" {
            filter = CIFilter(name: "CIPhotoEffectNoir")
        }
        filter?.setValue(currentImage!, forKey: kCIInputImageKey)
        return filter
    }
    
    override func handleTouchMovement(to rect: CGPoint) {
        super.handleTouchMovement(to: rect)
        super.handleTouchMovement(to: rect)
        
        let size = imageView.frame.size
        let bias = Float(rect.y) / Float(size.height)
        
        depthSlider.value = -(bias * 4 - 2)
        updateFilter()
        updateRender()
    }
    
    func updateFilter() {
        if currentFilter == nil {
            return
        }
        filterHelper.addFiterToChain(filter: currentFilter!,  value: 1,
                                     depthEnabled: depthEnabled,
                                     depth: CGFloat(depthSlider.value), slope: 1,
                                     filterSwitch: currentSwitch())
    }
    
}

//MARK: Collection Data Source
extension FilterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCollectionCell
        
        let tmpFilter = filter(name: filters[indexPath.row])
        
        if currentImage != nil && tmpFilter != nil {
            cell.configure(image: fImages[indexPath.row], name: filters[indexPath.row])
        }
        
        var selected = false
        if indexPath.row == backgroundIndex && currentSwitch() == .Background ||
            indexPath.row == foregroundIndex && currentSwitch() == .Foreground {
            selected = true
        }
        setSelected(selected: selected, cell: cell)
        
        return cell
    }
    
    func setSelected(selected: Bool, cell: UICollectionViewCell?) {
        guard let currentCell = cell else {
            return
        }
        currentCell.isSelected = selected
        if selected {
            currentCell.layer.cornerRadius = 0.8
            currentCell.layer.borderColor = UIColor.cyan.cgColor
            currentCell.layer.borderWidth = 2.0
        } else {
            currentCell.layer.cornerRadius = 0.8
            currentCell.layer.borderColor = UIColor.black.cgColor
            currentCell.layer.borderWidth = 2.0
        }
    }
    
}

//MARK: Collection Delegate
extension FilterViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let tmpFilter = filter(name: filters[indexPath.row]) else {
            return
        }
        
        switch currentSwitch() {
        case .Background:
            if backgroundIndex == indexPath.row {
                filterHelper.removeFilter(filterName: tmpFilter.name, filterSwitch: currentSwitch())
                setSelected(selected: false, cell: collectionView.cellForItem(at: IndexPath(item: backgroundIndex, section: 0)))
                currentFilter = nil
                backgroundIndex = -1
            } else {
                //Remove old filter
                if backgroundIndex != -1 {
                    guard let prevFilter = filter(name: filters[backgroundIndex]) else {
                        return
                    }
                    filterHelper.removeFilter(filterName: prevFilter.name, filterSwitch: currentSwitch())
                    setSelected(selected: false, cell: collectionView.cellForItem(at: IndexPath(item: backgroundIndex, section: 0)))
                    currentFilter = nil
                }
                
                //Set new filter
                currentFilter = tmpFilter
                setSelected(selected: true, cell: collectionView.cellForItem(at: indexPath)!)
                filterHelper.addFiterToChain(filter: tmpFilter, value: 1,
                                             depthEnabled: depthEnabled, depth: CGFloat(depthSlider.value),
                                             slope: 1, filterSwitch: currentSwitch())
                backgroundIndex = indexPath.row
            }
            break
        case .Foreground:
            if foregroundIndex == indexPath.row {
                filterHelper.removeFilter(filterName: tmpFilter.name, filterSwitch: currentSwitch())
                setSelected(selected: false, cell: collectionView.cellForItem(at: IndexPath(item: foregroundIndex, section: 0)))
                currentFilter = nil
                foregroundIndex = -1
            } else {
                //Remove old filter
                if foregroundIndex != -1 {
                    guard let prevFilter = filter(name: filters[foregroundIndex]) else {
                        return
                    }
                    setSelected(selected: false, cell: collectionView.cellForItem(at: IndexPath(item: foregroundIndex, section: 0)))
                    filterHelper.removeFilter(filterName: prevFilter.name, filterSwitch: currentSwitch())
                    currentFilter = nil
                }
                
                //Set new filter
                currentFilter = tmpFilter
                setSelected(selected: true, cell: collectionView.cellForItem(at: indexPath)!)
                filterHelper.addFiterToChain(filter: tmpFilter, value: 1,
                                             depthEnabled: depthEnabled, depth: CGFloat(depthSlider.value),
                                             slope: 1, filterSwitch: currentSwitch())
                foregroundIndex = indexPath.row
            }
            break
        }
        
        
        depthSlider.isEnabled = true
        updateRender()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
    
}

//MARK: Instance Factory
extension FilterViewController {
    
    static func getInstance(asset: PHAsset, cropped: CGRect?) -> FilterViewController {
        let story = UIStoryboard(name: "Main", bundle: nil)
        let controller = story.instantiateViewController(withIdentifier: "FilterViewController") as! FilterViewController
        controller.currentAsset = asset
        controller.croppedRect = cropped
        return controller
    }
}
