//
//  HomeViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/19.
//

import Foundation


//
//  LoginViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/10.
//

import UIKit
import WebKit
import SnapKit

class CentViewController: WebViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init web view
        initWebView()
        
        // 2. webpage loading
        urlReqeust = URLRequest(url: AppEnvironment.centPageURL, timeoutInterval: WEB_TIMEOUT)
        self.webView.load(urlReqeust)
        
        // 3. style
        changeUserInterfaceStyle()
        
        // 4. activity indicator
        startActivityIndicator()
    }
    
    override func initWebView() {
        super.initWebView()
        
        webView.snp.remakeConstraints{ make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
}

