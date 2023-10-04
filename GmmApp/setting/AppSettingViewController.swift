//
//  AppSettingViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/26.
//

import Foundation
import UIKit
import WebKit
import SnapKit

class AppSettingViewController: ModalWebViewController {
    
    let transitionManager = DrawerTransitionManager()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionManager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initWebView() {
        super.initWebView()
        
        webView.snp.remakeConstraints{ make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            if let tabBarController = self.presentingViewController as? UITabBarController {
                make.bottom.equalToSuperview().offset(-tabBarController.tabBar.frame.height)
            } else {
//                make.bottom.equalTo(self.view.safeAreaLayoutGuide)
                make.bottom.equalToSuperview()
            }
        }
    }
}
