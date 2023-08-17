//
//  BaseViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/10.
//

import UIKit
import WebKit
import CoreLocation


protocol InitialViewController {
    var initialViewController: Bool { get set}
}

class WebViewController: UIViewController {
    
    let WEB_TIMEOUT: TimeInterval = 10.0
    
    var webView: WKWebView!
    var urlReqeust: URLRequest!
    var webLoaded: Bool?
    static var locationManagers: [String: GUIDLocationManager] = [:]
    var activityIndicator: UIActivityIndicatorView!
    
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
        //webViewConfiguration.processPool = commonProcessPool
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
    
    func syncCookiesAtHTTPCookieStorage(completionHandler: (() -> Void)?) {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({(cookies: [HTTPCookie]) -> Void in
            for cookie: HTTPCookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            completionHandler?()
        })
    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        debug("viewWillAppear")
        if let webLoaded = self.webLoaded, !webLoaded {
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
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = window.frame
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
    }
    
    func stopActivityIndicator() {
        if let activityIndicator = self.activityIndicator, activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
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
        
        if let from = UserInformation.shared.from, UserInformation.shared.loginInfo != nil {
            var pathname = from
            if let searchIndex = from.firstIndex(of: "?") {
                pathname = String(from[from.startIndex..<searchIndex])
            }
            debug("from: \(from), pathname: \(pathname)")
            
            if AppEnvironment.centPageURL.absoluteString.hasSuffix(pathname) {
                self.tabBarController?.selectedIndex = 0
            } else if AppEnvironment.trcnPageURL.absoluteString.hasSuffix(pathname) {
                self.tabBarController?.selectedIndex = 2
            } else if !AppEnvironment.mainPageURL.absoluteString.hasSuffix(pathname) && from.count > 0 {
                let viewInfo = UserInformation.shared.fromViewInfo
                // shorter: 200, short: 250, standard: 300
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    var data: [String: Any] = ["location": from]
                    if viewInfo != nil {
                        data["viewInfo"] = viewInfo
                    }
                    self?.pushView(data)
                }
            }
            UserInformation.shared.from = nil
            UserInformation.shared.fromViewInfo = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debug("errored: \(error)")
        
        stopActivityIndicator()
        webLoaded = false
        alert(title: "접속 실패", message: "\n 사이트 접속에 실패했습니다. 서버나 네트워크를 확인해주세요!")
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
