//
//  ActivityIndicator.swift
//  MpgPrediction
//
//  Created by Nathan Dudley on 1/13/19.
//  Copyright © 2019 Nathan Dudley. All rights reserved.
//

import Foundation
import UIKit

//Modified from
//https://github.com/erangaeb/dev-notes/blob/master/swift/ViewControllerUtils.swift
class ActivityIndicator {
    
    var container: UIView = UIView()
    var loadingView: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    func show(on view: UIView) {
        container.frame = view.frame
        container.center = view.center
        container.backgroundColor = Theme.activityIndicatorBackgroundGray
        
        loadingView.frame = CGRect(origin: .zero, size: CGSize(width: 80, height: 80))
        loadingView.center = view.center
        loadingView.backgroundColor = Theme.activityIndicatorGray
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2);
        
        loadingView.addSubview(activityIndicator)
        container.addSubview(loadingView)
        view.addSubview(container)
        activityIndicator.startAnimating()
    }
    
    func hide(from view: UIView) {
        activityIndicator.stopAnimating()
        container.removeFromSuperview()
    }
}

