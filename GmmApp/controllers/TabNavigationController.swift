//
//  NavigationController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/22.
//

import Foundation
import UIKit

class TabNavigationController: UINavigationController {
    
    override var childForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        self.isNavigationBarHidden = true
    }
}
