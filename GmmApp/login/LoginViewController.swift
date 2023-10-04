//
//  LoginViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/10.
//

import UIKit
import WebKit
import SnapKit

class LoginViewController: WebViewController, InitViewController {
    
    @IBOutlet var launch: UIImageView!
    @IBOutlet var brand: UILabel!
    
    var initViewController = false
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        debug("traitCollectionDidChange")
        
        if !Theme.shared.isManualMode() && traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            debug("hasDifferentColorAppearance")
            self.setThemeWebViewController()
            setThemeViewController(viewController: self, themeMode: Theme.shared.getThemeMode())
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //        debug("\(type(of: self))")
        if Theme.shared.getUserInterfaceStyle() == .light {
            return .darkContent
        } else {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init app
        if initViewController {
            GmmApplication.shared.uiInitialize(self)
        }
        
        // 2. init web view
        initWebView()
        
        // 3. webpage loading
        urlReqeust = URLRequest(url: AppEnvironment.loginPageUrl)
        //self.webView.load(urlReqeust)
        
        // 4. views visible
        setThemeWebViewController()
        self.webView.load(urlReqeust)
        if initViewController {
            self.webView.isHidden = true
            // 10초 후 무조건 webview show
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.showWebView()
            }
        } else {
            self.launch.isHidden = true
            self.brand.isHidden = true
            startActivityIndicator()
        }
    }
}

extension LoginViewController: WebViewBridge, ShowWebViewController {
    func addMessageHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: "loggedIn")
    }
    
    func handleMessages(messageName: String, guid: String, data: [String : Any]) {
        switch messageName {
        case "loggedIn":
            let loginInfo = data["data"] as! [String: Any]
            UserInformation.shared.loginInfo = .init(accessToken: loginInfo["accessToken"] as! String,
                                                     refreshToken: loginInfo["refreshToken"] as! String,
                                                     appTimeout: loginInfo["appTimeout"] as! Int,
                                                     userInfo: loginInfo.filter({ !["accessToken", "refreshToken", "appTimeout", "remember"].contains($0.0)}))
            
            if let remember = loginInfo["remember"] as? Bool, remember {
                UserInformation.shared.setAutoLogin(remember)
                UserInformation.shared.setRefreshToken(UserInformation.shared.loginInfo?.refreshToken)
            } else {
                UserInformation.shared.setAutoLogin(false)
                UserInformation.shared.setRefreshToken(nil)
            }
            
            CookieUtils.syncToURLSession(webView: self.webView) {
                let mainTabBarController = self.storyboard!.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
                self.changeTabBarAppearance(mainTabBarController)
                if let sceneDelegate = self.windowScene.delegate as? SceneDelegate {
                    sceneDelegate.changeRootVC(mainTabBarController, animated: true)
                }
            }
        default:
            log("not matched message")
        }
    }
    
    func showWebView() {
        debug("showWebView")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.webView.isHidden else {
                return
            }
            
            self.changeUserInterfaceStyle()
            self.launch.isHidden = true
//            self.launch.removeFromSuperview()
            self.brand.isHidden = true
            self.webView.isHidden = false
            //            UIView.transition(with: self.webView, duration: 0.25,
            //                              options: .transitionCrossDissolve,
            //                              animations: {
            //                self.webView.alpha = 1 // x
            //            })
        }
    }
}
