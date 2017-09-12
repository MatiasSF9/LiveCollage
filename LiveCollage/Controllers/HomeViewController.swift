//
//  HomeViewController.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 12/09/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.title = "Deepix"
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didSelectCollage(_ sender: Any) {
        
    }
    
    @IBAction func didSelectDepth(_ sender: Any) {
        
    }
    
    @IBAction func didSelectEdit(_ sender: Any) {
        let photosController = PhotoCollectionViewController.getInstance()
        photosController.isEdit = true;
    }
    
    @IBAction func didSelectLivePicture(_ sender: Any) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditSegue" {
            let controller = segue.destination as! PhotoCollectionViewController
            controller.isEdit = true
        }
    }
    
}
