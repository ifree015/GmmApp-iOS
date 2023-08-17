//
//  LoginViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/10.
//

import UIKit
import WebKit
import SnapKit

class LoginViewController: WebViewController, InitialViewController {
    
    @IBOutlet var launch: UIImageView!
    @IBOutlet var brand: UILabel!
    
    var initialViewController = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init app
        GmmApplication.shared.initialize(self)
        
        // 2. init web view
        initWebView()
        
        // 3. webpage loading
        let urlReqeust = URLRequest(url: AppEnvironment.loginPageUrl)
        self.webView.load(urlReqeust)
        
        // 4. views visible
        if initialViewController {
            self.webView.isHidden = true
            // 5초 후 무조건 webview show
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.showWebView()
            }
        } else {
            self.launch.isHidden = true
            self.brand.isHidden = true
            changeUserInterfaceStyle()
        }
    }
}

extension LoginViewController: WebViewBridge {
    func addMessageHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: "showWebView")
        userContentController.add(self, name: "loggedIn")
    }
    
    func handleMessages(messageName: String, guid: String, data: [String : Any]) {
        switch messageName {
        case "showWebView":
            if initialViewController && self.webView.isHidden {
                let delayTime = 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    self.showWebView()
                }
            }
        case "loggedIn":
            let loginInfo = data["data"] as! [String: Any]
            UserInformation.shared.loginInfo = .init(accessToken: loginInfo["accessToken"] as! String,
                                                     refreshToken: loginInfo["refreshToken"] as! String,
                                                     appTimeout: loginInfo["appTimeout"] as! Int,
                                                     userInfo: loginInfo.filter({ !["accessToken", "refreshToken", "appTimeout", "rememeber"].contains($0.0)}))
            //            debug("loginInfo: \(UserInformation.shared.loginInfo!)")
            
            if let rememeber = loginInfo["rememeber"] as? Bool {
                UserInformation.shared.setAutoLogin(rememeber)
            } else {
                UserInformation.shared.setAutoLogin(false)
            }
            
            let mainTabBarController = self.storyboard!.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
            changeTabBarAppearance(mainTabBarController)
            if let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.changeRootVC(mainTabBarController, animated: true)
            }
        default:
            log("not matched message")
        }
    }
    
    func showWebView() {
        if (self.webView.isHidden) {
            self.changeUserInterfaceStyle(true)
            self.launch.isHidden = true
            //            self.launch.removeFromSuperview()
            self.brand.isHidden = true
            //            self.brand.removeFromSuperview()
            self.webView.isHidden = false
            //            UIView.transition(with: self.webView, duration: 0.25,
            //                              options: .transitionCrossDissolve,
            //                              animations: {
            //                self.webView.alpha = 1 // x
            //            })
        }
    }
}
