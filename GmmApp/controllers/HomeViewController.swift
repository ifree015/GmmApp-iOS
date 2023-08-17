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

class HomeViewController: WebViewController {
    
    @IBOutlet var launch: UIImageView!
    @IBOutlet var brand: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init web view
        initWebView()
        webView.scrollView.showsVerticalScrollIndicator = false
        
        // 2. webpage loading
         urlReqeust = URLRequest(url: AppEnvironment.mainPageURL, timeoutInterval: WEB_TIMEOUT)
        self.webView.load(urlReqeust)
        
        // 3. views visible
        if let initialViewController = self.navigationController?.tabBarController as? InitialViewController, initialViewController.initialViewController {
            self.webView.isHidden = true
            // 5초 후 무조건 webview show
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.showWebView()
            }
        } else {
            self.launch.isHidden = true
            self.brand.isHidden = true
            changeUserInterfaceStyle()
            startActivityIndicator()
        }
    }
    
    override func initWebView() {
        super.initWebView()
        
        webView.snp.updateConstraints { make in
            if let tabBarController = self.navigationController?.tabBarController {
                make.bottom.equalToSuperview().offset(-tabBarController.tabBar.frame.height)
            }
        }
    }
}

extension HomeViewController: WebViewBridge {
    func addMessageHandlers(_ userContentController: WKUserContentController) {
//        userContentController.add(self, name: "showWebView")
        userContentController.add(self, name: "loggedIn")
    }
    
    func handleMessages(messageName: String, guid: String, data: [String : Any]) {
        switch messageName {
//        case "showWebView":
//            if let initialViewController = self.navigationController?.tabBarController as? InitialViewController, initialViewController.initialViewController, self.webView.isHidden {
//                let delayTime = 0.2
//                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
//                    self.showWebView()
//                }
//            }
        case "loggedIn":
            let loginInfo = data["data"] as! [String: Any]
            UserInformation.shared.loginInfo = .init(accessToken: loginInfo["accessToken"] as! String,
                                                     refreshToken: loginInfo["refreshToken"] as! String,
                                                     appTimeout: loginInfo["appTimeout"] as! Int,
                                                     userInfo: loginInfo.filter({ !["accessToken", "refreshToken", "appTimeout"].contains($0.0)}))
            //            debug("loginInfo: \(UserInformation.shared.loginInfo!)")
            
            //            let delayTime = 0.1
            //            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            self.showWebView()
            //            }            
//            self.pushView(["location": "/trcndsbl/trcndsbldetail/11100/20230817100064"])
        default:
            log("not matched message")
        }
    }
    
    func showWebView() {
        if (self.webView.isHidden) {
            self.changeUserInterfaceStyle(true)
            self.launch.isHidden = true
            self.brand.isHidden = true
            self.webView.isHidden = false
            
            if let tabBarController = self.navigationController?.tabBarController {
                tabBarController.tabBar.isHidden = false
            }
            
//            debug("\(webView.frame)")
        }
    }
    
}
