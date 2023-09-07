//
//  BaseViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/10.
//

import UIKit
import WebKit
import CoreLocation

let commonProcessPool = WKProcessPool()

protocol InitialViewController {
    var initialViewController: Bool { get set}
}

protocol ShowWebViewController {
    func showWebView()
}

class WebViewController: UIViewController {
    
    let WEB_TIMEOUT: TimeInterval = 10.0
    
    var configShared: Bool = true
    var webView: WKWebView!
    var urlReqeust: URLRequest!
    var webLoaded: Bool?
    static var locationManagers: [String: GUIDLocationManager] = [:]
    var activityIndicator: UIActivityIndicatorView!
    var errorImageView: UIImageView?
        
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        debug("traitCollectionDidChange")
//        
//        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//            debug("hasDifferentColorAppearance")
//            setThemeViewController(viewController: self, themeMode: Theme.shared.getThemeMode())
//        }
//    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        //        debug("\(type(of: self))")
        if Theme.shared.getUserInterfaceStyle(self) == .light {
            return .darkContent
        } else {
            return .lightContent
        }
    }
    
    func initWebView() {
        // 1. configuration
        let webViewConfiguration = WKWebViewConfiguration()
        if configShared {
            //webViewConfiguration.websiteDataStore = WKWebsiteDataStore.default()
            webViewConfiguration.processPool = commonProcessPool
        } else {
            webViewConfiguration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        }
        // javaScript 사용 설정
        webViewConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true // WKWebpagePreferences
        // 자동으로 javaScript를 통해 새 창 열기 설정
        webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true // WKPreferences
        
        // 2. bridge: javascript -> native, native -> javascript
        webViewConfiguration.userContentController = JavascriptBridge.createWKUserContentController(self)
        
        // 3. webview 생성
        webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        if let appearance = UserDefaults.standard.string(forKey: "appearance") {
            if appearance == "dark" {
                self.webView.backgroundColor = UIColor(hexCode: "#121212")
            } else if appearance == "system" && self.traitCollection.userInterfaceStyle == .dark {
                self.webView.backgroundColor = UIColor(hexCode:"#121212")
            }
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        // white flash 방지
        self.webView.backgroundColor = UIColor.clear
        self.webView.isOpaque = false
        //        webView.alpha = 0
        webView.snp.makeConstraints { make in
            //$0.top.equalTo(self.view.safeAreaLayoutGuide)
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        //        let constraint: NSLayoutConstraint = webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        //        constraint.isActive = true
        //        webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        
        // 4. delegate
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // 5. etc.
        //        webView.scrollView.showsHorizontalScrollIndicator = false
        //        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = false
    }
    
    /// WKWebView의 쿠키들을 HTTPCookieStorage.shared에 동기화
    func syncCookiesAtHTTPCookieStorage(completionHandler: (() -> Void)?) {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({(cookies: [HTTPCookie]) -> Void in
            for cookie: HTTPCookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            completionHandler?()
        })
    }
    
    /// HTTPCookieStorage.shared의 쿠키들을 WKWebView에 동기화
    func syncCookiesAtWebView(completion: (() -> Void)?) {
        if let cookies = HTTPCookieStorage.shared.cookies {
            
            let group = DispatchGroup()
            cookies.forEach({ cookie in
                group.enter()
                self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            })
            group.notify(queue: .main) {
                completion?()
            }
            
        }
    }
    
    ///  인증  tokens 설정
    func setAuthTokens(completion: @escaping () -> Void) {
        //        guard let loginInfo = UserInformation.shared.loginInfo else {
        //            return
        //        }
        //        guard let accessTokenCookie = HTTPCookie(properties: [
        //            .domain: "",
        //            .path: "/",
        //            .name: "accessToken",
        //            .value: loginInfo.accessToken,
        //            .secure: (BuildMode.current == .debug) ? "FALSE" : "TRUE"
        ////            .expires: NSDate(timeIntervalSinceNow: TimeInterval(loginInfo.appTimeout * 60)
        //            ]) else { return }
        //        guard let refreshTokenCookie = HTTPCookie(properties: [
        //            .domain: "",
        //            .path: "/",
        //            .name: "refreshToken",
        //            .value: loginInfo.refreshToken,
        //            .secure: (BuildMode.current == .debug) ? "FALSE" : "TRUE"
        //            ]) else { return }
        //        let cookies = [accessTokenCookie, refreshTokenCookie]
        
        guard UserInformation.shared.loginInfo != nil, let webViewController = self.navigationController?.viewControllers[0] as? WebViewController else {
            return
        }
        webViewController.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({(cookies: [HTTPCookie]) -> Void in
            
            let group = DispatchGroup()
            cookies.forEach { cookie in
                group.enter()
                self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion()
            }
            
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        debug("viewWillAppear")
        if let webLoaded = self.webLoaded, !webLoaded {
            hideErrorImage()
            if webView.url == nil {
                webView.load(urlReqeust)
            } else {
                webView.reload()
            }
            startActivityIndicator()
        }
    }
    
    func reloadWebPage() {
        debug("reloadWebPage")
        
        if let webLoaded = self.webLoaded, webLoaded {
            webView.load(urlReqeust)
        }
    }
    
    func startActivityIndicator() {
        if self.activityIndicator != nil {
            return
        }
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = window.frame
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
    }
    
    func stopActivityIndicator() {
        guard let activityIndicator = self.activityIndicator else {
            return
        }
        
        self.activityIndicator = nil
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        activityIndicator.removeFromSuperview()
    }
    
    func showErrorImage() {
        if self.errorImageView != nil {
            return
        }
        
        let errorImageView = UIImageView()
        self.errorImageView = errorImageView
        errorImageView.alpha = 0
        errorImageView.tintColor = Theme.shared.getTabBarTintColor(self)
        errorImageView.image = UIImage(systemName: "quote.bubble")
        errorImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(errorImageView)
        errorImageView.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(self.view)
            make.width.height.equalTo(128)
        }
        UIView.animate(withDuration: 0.3, animations: {
            errorImageView.alpha = 1
        })
    }
    
    func hideErrorImage() {
        guard let errorImageView = self.errorImageView else {
            return
        }
        self.errorImageView = nil
        errorImageView.isHidden = true
        errorImageView.removeFromSuperview()
    }
}

extension WebViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        debug("locationManger: \(manager)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        if let guidLocationManager = manager as? GUIDLocationManager {
            Self.locationManagers.removeValue(forKey: guidLocationManager.guid)
            guidLocationManager.completion(locations.last)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debug("errored: \(error)")
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        debug("httpsHost: \(challenge.protectionSpace.host)")
#if DEBUG
        DispatchQueue.global(qos: .userInteractive).async {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
#else
        completionHandler(.performDefaultHandling, nil)
#endif
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            debug("requestURL: \(url.absoluteString), fragment: \(url.fragment ?? "")")
            if !url.absoluteString.hasPrefix(AppEnvironment.webRootUrl.absoluteString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debug("starting")
    }
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        debug("loading")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let loadedURL = webView.url?.absoluteString ?? ""
        debug("finished: \(loadedURL)")
        
        stopActivityIndicator()
        webLoaded = true
        
        if UserInformation.shared.loginInfo != nil {
            if let from = UserInformation.shared.from, from.count > 0 {
                debug("from: \(from)")
                
                var data: [String: Any] = ["location": from]
                if UserInformation.shared.fromViewInfo != nil {
                    data["viewInfo"] = UserInformation.shared.fromViewInfo
                }
                self.navigateView(data, reloaded: false, delayed: true)
                UserInformation.shared.from = nil
                UserInformation.shared.fromViewInfo = nil
            } else if let toLocation = UserInformation.shared.toLocation, toLocation.count > 0 {
                debug("toLocation: \(toLocation)")
                
                let data: [String: Any] = ["location": toLocation]
                self.navigateView(data, reloaded: false, delayed: true)
                UserInformation.shared.toLocation = nil
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debug("errored: \(error)")
        
        stopActivityIndicator()
        webLoaded = false
        let nsError = error as NSError;
        switch nsError.code {
        case -1009:
            alert(title: "네트워크 오류", message: "네트워크 연결을 확인하여 주세요!")
            if let showWebViewController = self as? ShowWebViewController {
                showWebViewController.showWebView()
            }
        case -1004:
            alert(title: "서버 오류", message: "사이트 접속에 실패했습니다. 서버를 확인하여 주세요!")
            if let showWebViewController = self as? ShowWebViewController {
                showWebViewController.showWebView()
            }
        default:
            alert(title: "접속 실패", message: nsError.localizedDescription)
            //alert(title: "접속 실패", message: "\n 사이트 접속에 실패했습니다. 서버나 네트워크를 확인해주세요!")
        }
        showErrorImage()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debug("errored: \(error)")
        
        stopActivityIndicator()
        webLoaded = false
        //alert(title: "로딩 실패", message: "\n 웹 페이지(\(webView.url!.absoluteString)) 로딩에 실패했습니다!")
    }
    
    func alert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension WebViewController: WKUIDelegate {
    
    //    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    //        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
    //        let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
    //            completionHandler()
    //        }
    //        alertController.addAction(okAction)
    //        present(alertController, animated: true, completion: nil)
    //    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            log("openURL: \(url)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        debug(webView.url?.absoluteString)
    }
}
