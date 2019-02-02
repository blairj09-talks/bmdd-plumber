//
//  MpgPredictionViewController.swift
//  MpgPrediction
//
//  Created by Nathan Dudley on 1/13/19.
//  Copyright © 2019 Nathan Dudley. All rights reserved.
//

import UIKit

class PredictionViewController: UIViewController {

    
    //MARK: IBOutlets
    @IBOutlet weak var btnPredict: UIButton!
    @IBOutlet weak var lblHorsepower: UILabel!
    @IBOutlet weak var lblResult: UILabel!
    @IBOutlet weak var lblMilesPerGallon: UILabel!
    @IBOutlet weak var sgmCylinders: UISegmentedControl!
    @IBOutlet weak var sldHorsepower: UISlider!
    
    //MARK: Private Variables
    private var selectedHorsepower: Int!
    private var selectedCylinderCount: Int!
    private var activityIndicator: ActivityIndicator!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControls()
        self.selectedHorsepower = Int(round(sldHorsepower.value/10) * 10)
        self.selectedCylinderCount = 2
    }
    
    //MARK: Private functions
    fileprivate func setupControls() {
        Theme.applyButtonTheme(button: btnPredict, state: .normal)
        Theme.applyNavigationBarTheme(navBar: self.navigationController!.navigationBar)
        
        sgmCylinders.setTitle("2", forSegmentAt: 0)
        sgmCylinders.setTitle("4", forSegmentAt: 1)
        sgmCylinders.setTitle("6", forSegmentAt: 2)
        
        self.hideResult()
        self.activityIndicator = ActivityIndicator()
    }
    
    fileprivate func hideResult() {
        lblMilesPerGallon.isHidden = true
        lblResult.isHidden = true
        btnPredict.isHidden = false
    }
    
    fileprivate func showResult() {
        lblMilesPerGallon.isHidden = false
        lblResult.isHidden = false
        if lblResult.bounds.maxY > btnPredict.bounds.minY {
            btnPredict.isHidden = true
        }
    }
    
    
    //MARK: IBActions
    @IBAction func btnPredictPressed(_ sender: UIButton) {
        Theme.applyButtonTheme(button: sender, state: .selected)
        let endpoint = "https://colorado.rstudio.com/rsc/carmodel/predict"
        let parameters = WebRequestHandler.createHeaderParameters(parameters:
            ["cyl": self.selectedCylinderCount,
             "hp": self.selectedHorsepower])
        
        let predictionFinished: (NSArray) -> () = { (webResponse) in
            self.activityIndicator.hide(from: self.view)
            Theme.applyButtonTheme(button: self.btnPredict, state: .normal)
            
            let prediction = webResponse[0] as? Double ?? 0
            self.lblResult.text = "\(Double(round(100*prediction)/100))"
            
            self.showResult()
        }
        
        let predictionFailed: (String) -> () = { (error) in
            self.activityIndicator.hide(from: self.view)
            Theme.applyButtonTheme(button: self.btnPredict, state: .normal)
            self.hideResult()
            
            print(error)
            
            let alert = UIAlertController(title: "Error", message: "Could not connect to server.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        self.activityIndicator.show(on: self.view)
        
        WebRequestHandler.sendWebRequest(httpMethod: "POST", endpoint: endpoint, httpBody: parameters, onCompletion: predictionFinished, onError: predictionFailed)
    }
    
    
    @IBAction func sldHorsepowerChanged(_ sender: UISlider) {
        self.selectedHorsepower = Int(round(sender.value/10) * 10)
        lblHorsepower.text = "\(self.selectedHorsepower ?? 0)"
        self.hideResult()
    }
    
    @IBAction func sgmCylindersChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.selectedCylinderCount = 2
        case 1:
            self.selectedCylinderCount = 4
        case 2:
            self.selectedCylinderCount = 6
        default:
            self.selectedCylinderCount = 2
        }
        self.hideResult()
    }
    
}
