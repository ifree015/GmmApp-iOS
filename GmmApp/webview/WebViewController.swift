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

protocol InitViewController {
    var initViewController: Bool { get set}
}

protocol ShowWebViewController {
    func showWebView()
}

class WebViewController: UIViewController {
    
    let WEB_TIMEOUT: TimeInterval = 10.0
    
    var configShared = true
    var urlReqeust: URLRequest!
    var webView: WKWebView!
//    var webLoaded: Bool?
    var refreshable = true
    var activityIndicator: UIActivityIndicatorView!
    var errorImageView: UIImageView?
    static var locationManagers: [String: GUIDLocationManager] = [:]
    
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
//        if Theme.shared.getUserInterfaceStyle(self) == .light {
//            return .darkContent
//        } else {
            return .lightContent
//        }
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
//        webView.backgroundColor = Theme.shared.getBackgroundColor(self)
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
        if refreshable {
            webView.scrollView.refreshControl = UIRefreshControl()
            webView.scrollView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        }
        
        // 5. etc.
        //        webView.scrollView.showsHorizontalScrollIndicator = false
        //        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = false
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        debug("viewWillAppear")
//        //        if let webLoaded = self.webLoaded, !webLoaded {
//        //            hideErrorImage()
//        //            if webView.url == nil {
//        //                webView.load(urlReqeust)
//        //            } else {
//        //                webView.reload()
//        //            }
//        //            startActivityIndicator()
//        //        }
//    }
    
    func reloadWebPage() {
        debug("reloadWebPage")
        
        //        if let webLoaded = self.webLoaded, webLoaded {
        //            webView.load(urlReqeust)
        //        }
        guard self.webView != nil else { return }
        
        hideErrorImage()
        if webView.url == nil {
            webView.load(urlReqeust)
        } else {
            webView.reload()
        }
    }
    
    @objc func handleRefreshControl() {
        debug("handleRefreshControl")
        
        reloadWebPage()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
////        DispatchQueue.main.async {
////            self.webView.scrollView.refreshControl?.endRefreshing()
//            //self.webView.scrollView.setContentOffset(. init(x: 0, y: 0), animated: true)
//        }
    }
    
    func startActivityIndicator() {
        guard self.activityIndicator == nil else {
            return
        }
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = window.frame
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
    }
    
    func stopActivityIndicator() {
        guard self.activityIndicator != nil else {
            return
        }
        
        //        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        activityIndicator.removeFromSuperview()
        self.activityIndicator = nil
    }
    
    func showErrorImage() {
        guard self.errorImageView == nil else {
            return
        }
        
        let errorImageView = UIImageView()
        self.errorImageView = errorImageView
        errorImageView.alpha = 0
        errorImageView.tintColor = Theme.shared.getTabBarTintColor()
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
        
        errorImageView.isHidden = true
        errorImageView.removeFromSuperview()
        self.errorImageView = nil
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

        if let showWebViewController = self as? ShowWebViewController {
            showWebViewController.showWebView()
        }

        stopActivityIndicator()
        if let isRefreshing = self.webView.scrollView.refreshControl?.isRefreshing, isRefreshing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.webView.scrollView.refreshControl?.endRefreshing()
                //self.webView.scrollView.contentOffset.y = 0
            }
        }
        
//        webLoaded = true

        if UserInformation.shared.loginInfo != nil {
            if UserInformation.shared.locations.count > 0 {
                let locationData = UserInformation.shared.locations.removeFirst()
                debug("locationData: \(locationData)")

                self.navigateView(locationData)
            }
        }

        if UserInformation.shared.loginInfo != nil, let range: Range<String.Index> = loadedURL.range(of: "pushNtfcPt=") {
            //let startIndex: Int = location.distance(from: location.startIndex, to: range.upperBound)
            //pushNtfcPt = location[startIndex..<location.count]
            let pushNtfcPt = String(loadedURL[range.upperBound..<loadedURL.endIndex]) // Substring
            debug("pushNtfcPt: \(pushNtfcPt)")
            NotificationService.shared.updateNtfcPtPrcgYn(pushNtfcPt)
         }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debug("errored: \(error)")

        stopActivityIndicator()
        if let isRefreshing = self.webView.scrollView.refreshControl?.isRefreshing, isRefreshing {
            self.webView.scrollView.refreshControl?.endRefreshing()
            self.webView.scrollView.contentOffset.y = 0
        }

//        webLoaded = false
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
        if let isRefreshing = self.webView.scrollView.refreshControl?.isRefreshing, isRefreshing {
            self.webView.scrollView.refreshControl?.endRefreshing()
            self.webView.scrollView.contentOffset.y = 0
        }
//        webLoaded = false
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
