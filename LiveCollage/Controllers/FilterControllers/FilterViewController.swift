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
    var bSelections = [false, false, false, false, false, false, false]
    var fSelections = [false, false, false, false, false, false, false]
    
    var currentFilter:CIFilter? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    @IBAction func onSegmentChange(_ sender: Any) {
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
            cell.configure(ciimage: currentImage!, filter: tmpFilter!)
        }
        
        var selected = false
        switch currentSwitch() {
        case .Background:
            selected = bSelections[indexPath.row]
        case .Foreground:
            selected = fSelections[indexPath.row]
        }
        
        setSelected(selected: selected, cell: cell)
        
        return cell
    }
    
    func setSelected(selected: Bool, cell: UICollectionViewCell) {
        if selected {
            cell.layer.cornerRadius = 0.8
            cell.layer.borderColor = UIColor.cyan.cgColor
            cell.layer.borderWidth = 2.0
        } else {
            cell.layer.cornerRadius = 0.8
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 2.0
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
            bSelections[indexPath.row] = !bSelections[indexPath.row]
            break
        case .Foreground:
            fSelections[indexPath.row] = !fSelections[indexPath.row]
            break
        }
        
        if filterHelper.getFilter(filterName: tmpFilter.name, filterSwitch: currentSwitch() ) == nil {
            filterHelper.addFiterToChain(filter: tmpFilter, value: 1,
                                         depthEnabled: depthEnabled, depth: CGFloat(depthSlider.value),
                                         slope: 1, filterSwitch: currentSwitch())
            currentFilter = tmpFilter
            setSelected(selected: true, cell: collectionView.cellForItem(at: indexPath)!)
        } else {
            filterHelper.removeFilter(filterName: tmpFilter.name, filterSwitch: currentSwitch())
            currentFilter = nil
            setSelected(selected: false, cell: collectionView.cellForItem(at: indexPath)!)
        }
        depthSlider.isEnabled = true
        updateRender()
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
