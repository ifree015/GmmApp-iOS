//
//  DrawerWebViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/25.
//

import UIKit

class DrawerWebViewController: WebViewController {

    let transitionManager = DrawerTransitionManager()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionManager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
