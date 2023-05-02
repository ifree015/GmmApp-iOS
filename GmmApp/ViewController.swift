//
//  ViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/25.
//

import UIKit
import WebKit
import CoreLocation
import SnapKit
import Toast_Swift

class ViewController: UIViewController {
    
    @IBOutlet var launch: UIImageView!
    @IBOutlet var brand: UILabel!
    var webView: WKWebView!
    var locationManager: CLLocationManager!
    var locationManagers: [String: GUIDLocationManager] = [:]
    var toLocation: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init toast
        initToast()
        // 2. theme mode
        //changeUserInterfaceStyle()
        
        // 3. init web view
        initWebView()
        
        // 4. 최초 실행이라면
        if !UserDefaults.standard.bool(forKey: "FirstRunned") {
            UserDefaults.standard.set(true, forKey: "FirstRunned")
            initLocationManager()
        } else {
            //            if !PermissionUtils.hasPermissions(permissions: "location") {
            //                self.view.makeToast("일부 권한이 허용되지 않았습니다!")
            //            }
        }
        
        // 5. webpage loading
        let toURL: URL
        if let url = toLocation, url.count > 0 {
            toURL = URL(string: url)!
        } else {
            toURL = AppEnvironment.webRootUrl
        }
        let urlReqeust = URLRequest(url: toURL)
        self.webView.load(urlReqeust)
        
        // 6. 1.5초 후 무조건 webview show
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showWebView()
        }
    }
    
    func initToast() {
        // create a new style
        var style = ToastStyle()
        // this is just one of many style options
        style.backgroundColor = .darkGray
        // or perhaps you want to use this style for all toasts going forward?
        // just set the shared style and there's no need to provide the style again
        ToastManager.shared.style = style
        
        // basic usage
        //self.view.makeToast("This is a piece of toast")
    }
    
    func initWebView() {
        // 1. configuration
        let webViewConfiguration = WKWebViewConfiguration()
        // javaScript 사용 설정
        webViewConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true // WKWebpagePreferences
        // 자동으로 javaScript를 통해 새 창 열기 설정
        webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true // WKPreferences
        
        // 2. bridge: javascript -> native, native -> javascript
        webViewConfiguration.userContentController = JavascriptBridge.createWKUserContentController(messageHandler: self)
        
        // 3. webview 생성
        webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        if let appearance = UserDefaults.standard.string(forKey: "Appearance") {
            if appearance == "dark" {
                self.webView.backgroundColor = UIColor(red: 18, green: 18, blue: 18) // #121212
            } else if appearance == "system" && self.traitCollection.userInterfaceStyle == .dark {
                self.webView.backgroundColor = UIColor(red: 18, green: 18, blue: 18) // #121212
            }
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        webView.isHidden = true
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
        webView.navigationDelegate = self
        webView.uiDelegate = self
        //        webView.scrollView.showsHorizontalScrollIndicator = false
        //        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = true
    }
    
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

extension ViewController: WKNavigationDelegate {
    
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
            let fragment =  url.fragment ?? ""
            debug("requestURL: \(url), fragment: \(fragment)")
            decisionHandler(.allow)
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
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debug("errored: \(error)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debug("errored: \(error)")
    }
}

extension ViewController: WKUIDelegate {
    
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

extension ViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        debug("locationManger: \(locationManager == manager)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        if let guidLocationManager = manager as? GUIDLocationManager {
            locationManagers.removeValue(forKey: guidLocationManager.guid)
            guidLocationManager.completion(locations.last)
        } else if let location = locations.last  {
            debug("\(location)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debug("errored: \(error)")
    }
}

