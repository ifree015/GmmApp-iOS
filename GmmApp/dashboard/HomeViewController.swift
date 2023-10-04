//
//  HomeViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/19.
//

import Foundation
import UIKit
import WebKit
import SnapKit
import SYBadgeButton

class HomeViewController: WebViewController {
    
    @IBOutlet var launch: UIImageView!
    @IBOutlet var brand: UILabel!
    var notificationButton: SYBadgeButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init view controller
        initViewController()
        
        // 2. init web view
        initWebView()
        //        webView.scrollView.refreshControl?.alpha = 0.2
        webView.scrollView.showsVerticalScrollIndicator = false
        
        // 3. webpage loading
        urlReqeust = URLRequest(url: AppEnvironment.mainPageURL, timeoutInterval: WEB_TIMEOUT)
        //        self.webView.load(urlReqeust)
        
        // 4. views visible
        if let initViewController = self.navigationController?.tabBarController as? InitViewController, initViewController.initViewController {
            self.webView.isHidden = true
            LoginService.shared.fetchAutoLogin { result in
                self.processLogin(result)
            }
        } else {
            self.webView.load(urlReqeust)
            self.launch.isHidden = true
            self.brand.isHidden = true
            setThemeWebViewController()
            startActivityIndicator()
            
            AppService.shared.fetchLstAppVer {
                self.checkAppVersion($0)
            }
        }
        //self.view.makeToast("This is a piece of toast")
    }
    
    func initViewController() {
        if let initViewController = self.navigationController?.tabBarController as? InitViewController, initViewController.initViewController {
            self.navigationController?.navigationBar.isHidden = true
        }
        changeNavigationBarAppearance(self.navigationController?.navigationBar)
        
        //        let titleLabel = UILabel()
        //        titleLabel.text = "Home"
        //        titleLabel.textColor = .white
        //        titleLabel.font = UIFont.systemFont(ofSize: CGFloat(20))
        //        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: titleLabel)
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Home", primaryAction: UIAction { _ in
            NotificationService.shared.fetchNewNtfcPtNcnt {
                self.updateNewNtfcNcnt($0)
            }
            
            self.reloadWebPage()
        })
        navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(20))], for: .normal)
        //        navigationItem.leftBarButtonItem?.isEnabled = false
        
        var configuration = UIButton.Configuration.tinted()
        //        configuration.title = "Search...   "
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.5375)
        //        var titleContainer = AttributeContainer()
        //        titleContainer.font = UIFont.systemFont(ofSize: 14)
        //        titleContainer.foregroundColor = UIColor.white.withAlphaComponent(0.43)
        //        configuration.attributedTitle = AttributedString("Search...   ", attributes: titleContainer)
        var titleAttribute = AttributedString.init("Search...   ")
        titleAttribute.font = .systemFont(ofSize: 14.0)
        configuration.attributedTitle = titleAttribute
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 10)
        configuration.image = UIImage(systemName: "magnifyingglass")
        configuration.imagePadding = 8
        let searchButton = UIButton(configuration: configuration, primaryAction: UIAction { _ in
            var data: [String: Any] = ["location": "/trcndsblvhclsearch?viewMode=modal"]
            data["viewInfo"] = ["barHidden": true]
            self.navigateView(data)
        })
        
        configuration = UIButton.Configuration.plain()
        //        configuration.buttonSize = .small
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16)
        configuration.image = UIImage(systemName: "bell")
        notificationButton = SYBadgeButton(configuration: configuration, primaryAction: UIAction { _ in
            var data: [String: Any] = ["location": "/notification"]
            data["viewInfo"] = ["title": "알림"]
            self.navigateView(data)
        })
        notificationButton.badgeValue = ""
        notificationButton.badgeBackgroundColor = UIColor(hexCode: "#d32f2f")
        
        configuration = UIButton.Configuration.plain()
        configuration.contentInsets.leading = 0
        configuration.contentInsets.trailing = 0
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16)
        configuration.image = UIImage(systemName: "line.3.horizontal")
        let menuButton = UIButton(configuration: configuration, primaryAction: UIAction { _ in
            let appMenuViewController = AppMenuViewController()
            self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
            self.navigationController?.pushViewController(appMenuViewController, animated: true)
        })
        
        let righthStackview = UIStackView.init(arrangedSubviews: [searchButton, notificationButton, menuButton])
        righthStackview.distribution = .equalSpacing
        righthStackview.axis = .horizontal
        righthStackview.alignment = .center
        righthStackview.spacing = 4
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: righthStackview)
    }
    
    override func initWebView() {
        super.initWebView()
        
        webView.snp.remakeConstraints { make in
            if let navigationBar = self.navigationController?.navigationBar {
                if navigationBar.isHidden {
                    make.top.equalTo(self.view.safeAreaLayoutGuide).offset(navigationBar.frame.height)
                } else {
                    make.top.equalTo(self.view.safeAreaLayoutGuide)
                }
            }
            make.leading.trailing.equalToSuperview()
            if let tabBarController = self.navigationController?.tabBarController {
                make.bottom.equalToSuperview().offset(-tabBarController.tabBar.frame.height)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debug("viewWillAppear")
        
        if !self.webView.isHidden {
            self.navigationController?.navigationBar.isHidden = false
        }
        
        if UserInformation.shared.loginInfo != nil {
            NotificationService.shared.fetchNewNtfcPtNcnt {
                self.updateNewNtfcNcnt($0)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveNewNotification(_:)), name: NSNotification.Name.newNotification, object: nil)
        NotificationService.shared.startNotificationTimer()
    }
    
    func processLogin(_ result: Result<[String: Any], Error>) {
        switch result {
        case .success(let data):
            if let loginInfo = data["data"] as? [String: Any] {
                UserInformation.shared.loginInfo = .init(accessToken: loginInfo["accessToken"] as! String,
                                                         refreshToken: loginInfo["refreshToken"] as! String,
                                                         appTimeout: loginInfo["appTimeout"] as! Int,
                                                         userInfo: loginInfo.filter({ !["accessToken", "refreshToken", "appTimeout"].contains($0.0)}))
                UserInformation.shared.setRefreshToken(UserInformation.shared.loginInfo?.refreshToken)
                
                DispatchQueue.main.async {
                    CookieUtils.syncToWebView(webView: self.webView) {
                        JavascriptBridge.setUserInfo(self.webView.configuration.userContentController)
                        self.webView.load(self.urlReqeust)
                        // self.showWebView()
                    }
                }
            }
        case .failure(let error):
            log("error: \(String(describing: error))")
            DispatchQueue.main.async {
                let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "LoginViewController")
                if let sceneDelegate = self.windowScene.delegate as? SceneDelegate {
                    sceneDelegate.changeRootVC(loginViewController, animated: true)
                }
            }
        }
    }
    
    @objc func didRecieveNewNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let result = userInfo["result"] as? Result<[String: Any], Error> else {
            return
        }
        
        updateNewNtfcNcnt(result)
    }
    
    func updateNewNtfcNcnt(_ result: Result<[String: Any], Error>) {
        guard UserInformation.shared.loginInfo != nil else {
            return
        }
        
        switch result {
        case .success(let data):
            if let data = data["data"] as? [String: Any] {
                DispatchQueue.main.async {
                    if let newNtfcNcnt = data["newNtfcNcnt"] as? Int {
                        if newNtfcNcnt > 99 {
                            self.notificationButton.badgeValue = "99+"
                        } else if newNtfcNcnt == 0 {
                            self.notificationButton.badgeValue = ""
                        } else {
                            self.notificationButton.badgeValue = String(newNtfcNcnt)
                        }
                    }
                    if let pushNtfcNcnt = data["pushNtfcNcnt"] as? Int {
                        UIApplication.shared.applicationIconBadgeNumber = pushNtfcNcnt
                    }
                }
            }
        case .failure(let error):
            log("error: \(String(describing: error))")
            DispatchQueue.main.async {
                CookieUtils.syncToURLSession(webView: self.webView)
            }
            //                  switch error {
            //                case FetchError.bizError(let code, _, _) where code == "gmm.err.003":
            //                    fallthrough
            //                default:
            //                    log("error: \(String(describing: error))")
            //                }
        }
    }
    
    func checkAppVersion(_ result: Result<[String: Any], Error>) {
        guard UserInformation.shared.loginInfo != nil else {
            return
        }
        
        switch result {
        case .success(let data):
            //debug(data)
            if let appInfo = data["data"] as? [String: Any], appInfo.count > 0 {
                let title = appInfo["ntfcTtlNm"] as? String ?? "App Update 알림"
                var message: String?
                var attributedMessage: NSMutableAttributedString?
                if let ntfcTtlNm = appInfo["ntfcTtlNm"] as? String {
                    message = ntfcTtlNm
                } else {
                    // attributedMessage = NSMutableAttributedString(string: "새 버전(", attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.gray])
                    // attributedMessage?.append(NSAttributedString(string: , attributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.gray]))
                    // attributedMessage?.append(NSAttributedString(string: ")의 App을 설치하시겠습니까?", attributes: [.font: UIFont.systemFont(ofSize: 16))])
                    attributedMessage = NSMutableAttributedString(string: "새 버전(", attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.gray]).bold(string: appInfo["moappVer"] as? String ?? "", fontSize: 16)
                        .regular(string: ")의 App을 설치하시겠습니까?", fontSize: 16)
                }
                var leftActionTitle: String?
                if let rnwlNedYn = appInfo["rnwlNedYn"] as? String, rnwlNedYn != "Y" {
                    leftActionTitle = "취소"
                }
                
                DispatchQueue.main.async {
                    self.informPopup(title: title, message: message, attributedMessage: attributedMessage, leftActionTitle: leftActionTitle, rightActionTitle: "설치", rightActionCompletion: {
                        let url = URL(string: data["cnctMoappUrlVal"] as! String)
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    })
                }
            }
        case .failure(let error):
            log("error: \(String(describing: error))")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        debug("viewDidDisappear")
        
        NotificationCenter.default.removeObserver(self, name: .newNotification, object: nil)
        NotificationService.shared.stopNotificationTimer()
    }
}

extension HomeViewController: ShowWebViewController {
    
    func showWebView() {
        debug("showWebView")
        guard self.webView.isHidden else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.changeUserInterfaceStyle()
            
            self.navigationController?.navigationBar.isHidden = false
//            self.webView.layoutIfNeeded()
            self.launch.isHidden = true
            self.brand.isHidden = true
            self.webView.isHidden = false
            self.navigationController?.tabBarController?.tabBar.isHidden = false
            
            self.webView.snp.updateConstraints{ make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(0)
            }
            
            AppService.shared.fetchLstAppVer {
                self.checkAppVersion($0)
            }
        }
    }
}
