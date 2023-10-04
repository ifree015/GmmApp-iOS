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

class TrcnViewController: WebViewController {
    
   override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init view controller
        initViewController()
        
        // 2. init web view
        initWebView()
        
        // 3. webpage loading
        urlReqeust = URLRequest(url: AppEnvironment.trcnPageURL, timeoutInterval: WEB_TIMEOUT)
        self.webView.load(urlReqeust)
        
        // 4. style
        setThemeWebViewController()
        
        // 5. activity indicator
        startActivityIndicator()
    }
    
    func initViewController() {
        changeNavigationBarAppearance(self.navigationController?.navigationBar)
        navigationItem.title = "단말기 장애"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(navigateMenu))
    }
    
    @objc func navigateMenu() {
        let appMenuViewController = AppMenuViewController()
        self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
        self.navigationController?.pushViewController(appMenuViewController, animated: true)
    }
    
    override func initWebView() {
        super.initWebView()
        
        webView.snp.remakeConstraints{ make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
}
