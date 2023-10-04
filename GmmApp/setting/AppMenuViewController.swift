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


class AppMenuViewController: WebViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init view controller
        initViewController()
        
        // 2. init web view
        initWebView()
        
        // 3. webpage loading
        let url = URL(string: AppEnvironment.mainPageURL.absoluteString + "setting/menu")
        urlReqeust = URLRequest(url: url!)
        self.webView.load(urlReqeust)
            
        // 4. style
        setThemeWebViewController()
        
        // 5. activity indicator
        // startActivityIndicator()
    }
        
    func initViewController() {
        changeNavigationBarAppearance(self.navigationController?.navigationBar)
        navigationItem.title = "메뉴"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(drawAppSetting))
    }
    
    @objc func drawAppSetting() {
        let appSettingViewController = AppSettingViewController()
        appSettingViewController.location = "setting/setting"
        appSettingViewController.viewInfo = ["title": "설정"]
        present(appSettingViewController, animated: true)
    }
    
    override func initWebView() {
        super.initWebView()

        webView.snp.remakeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
}
