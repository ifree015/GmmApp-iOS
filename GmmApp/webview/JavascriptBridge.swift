//
//  JavascriptBridge.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation
import WebKit
import CoreLocation

extension WKWebView {
    func postMessage(eventName: String = "webview", data: String) {
        let script = """
        window.dispatchEvent(
          new CustomEvent('\(eventName)', {
            detail: { data: '\(data)' }
        }));
    """
        debug("\(script)")
        self.evaluateJavaScript(script) {
            (data, err) in
            if let err = err {
                log("err: \(err)")
            }
        }
    }
}

class JavascriptBridge {
    
    static func createWKUserContentController(_ webViewController: WebViewController) -> WKUserContentController {
        let userContentController = WKUserContentController()
        
        userContentController.add(webViewController, name: "getAppName")
        userContentController.add(webViewController, name: "getAppInfo")
        userContentController.add(webViewController, name: "getPhoneNumber")
        userContentController.add(webViewController, name: "isPermission")
        userContentController.add(webViewController, name: "getLastKnownLocation")
        userContentController.add(webViewController, name: "showToastMessage")
        
        userContentController.add(webViewController, name: "loginView")
        userContentController.add(webViewController, name: "setThemeMode")
        userContentController.add(webViewController, name: "updatePushNtfcNcnt")
        userContentController.add(webViewController, name: "navigateView")
        userContentController.add(webViewController, name: "modalView")
        userContentController.add(webViewController, name: "pushView")
        userContentController.add(webViewController, name: "setViewInfo")
        userContentController.add(webViewController, name: "goBack")
        userContentController.add(webViewController, name: "loggedOut")
        
        if let bridge = webViewController as? WebViewBridge {
            bridge.addMessageHandlers(userContentController)
        }
        
        setUserInfo(userContentController)
        if let data = try? JSONEncoder().encode(AppInfo.getAppInfo()), let value = String(data: data, encoding: .utf8) {
            //            debug("\(value)")
            let script = WKUserScript(
                source: "window.sessionStorage.setItem('appInfo', '\(value)');",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContentController.addUserScript(script)
        }
        
#if DEBUG
        let source = "function captureLog(msg) { window.webkit.messageHandlers.consoleLog.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        userContentController.add(ConsoleLogHandler(), name: "consoleLog")
#endif
        
        return userContentController
    }
    
    static func setUserInfo(_ userContentController: WKUserContentController) {
        if let userInfo = UserInformation.shared.loginInfo?.userInfo, let data = try? JSONSerialization.data(withJSONObject: userInfo), let value = String(data: data, encoding: .utf8) {
            //            debug("\(value)")
            let script = WKUserScript(
                source: "window.sessionStorage.setItem('userInfo', '\(value)');",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContentController.addUserScript(script)
        }
    }
}

protocol WebViewBridge {
    func addMessageHandlers(_ userContentController: WKUserContentController)
    func handleMessages(messageName: String, guid: String, data: [String: Any])
}

class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        debug("consoleLog: \(message.body)")
    }
}

extension WebViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let data = message.body as? [String: Any], let guid = data["guid"] as? String else {
            return
        }
        debug("messageName: \(message.name), data: \(data)")
        
        switch message.name {
        case "getAppName":
            executePromise(guid: guid, data: "GmmApp")
        case "getAppInfo":
            do {
                let jsonData = try JSONEncoder().encode(AppInfo.getAppInfo())
                executePromise(guid: guid, data: String(data: jsonData, encoding: .utf8)!)
            } catch {
                log(error.localizedDescription)
                executePromise(guid: guid)
            }
        case "getPhoneNumber":
            executePromise(guid: guid, data: UserInformation.shared.getPhoneNumber() ?? "")
        case "isPermission":
            executePromise(guid: guid, data: PermissionUtils.hasPermissions(permissions: data["data"] as! String).description)
        case "getLastKnownLocation":
            let guidLocationManager = GUIDLocationManager(guid: guid, completion: {
                location in
                if let location = location {
                    let json: [String: Any] = [
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude,
                    ]
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: json)
                        self.executePromise(guid: guid, data: String(data: jsonData, encoding: .utf8)!)
                    } catch {
                        log(error.localizedDescription)
                        self.executePromise(guid: guid)
                    }
                } else {
                    self.view.makeToast("It does not has location permission!")
                    self.executePromise(guid: guid)
                }
            })
            if guidLocationManager.isPermission() {
                guidLocationManager.delegate = self
                guidLocationManager.desiredAccuracy = kCLLocationAccuracyBest
                //                guidLocationManager.requestWhenInUseAuthorization()
                guidLocationManager.startUpdatingLocation()
                Self.locationManagers.updateValue(guidLocationManager, forKey: guid)
            }
        case "showToastMessage":
            debug("\(data["data"]!)")
            if let message = data["data"] as? String {
                self.view.makeToast(message)
            }
        case "loginView":
            loginView(data["data"] as! [String: Any])
        case "setThemeMode":
            guard let themeMode = data["data"] as? String else {return}
            debug("themeMode: \(themeMode)")
            self.setTheme(themeMode)
        case "updatePushNtfcNcnt":
            guard let pushNtfcNcnt = data["data"] as? Int else {return}
            debug("pushNtfcNcnt: \(pushNtfcNcnt)")
            UIApplication.shared.applicationIconBadgeNumber = pushNtfcNcnt
        case "navigateView":
            self.navigateView(data["data"] as! [String: Any])
        case "modalView":
            self.modalView(data["data"] as! [String: Any])
        case "pushView":
            self.pushView(data["data"] as! [String: Any])
        case "setViewInfo":
            self.setViewInfo(viewInfo: data["data"] as! [String: Any])
        case "goBack":
            self.goBack()
        case "loggedOut":
            self.loggedOut()
        default:
            if let bridge = self as? WebViewBridge {
                bridge.handleMessages(messageName: message.name, guid: guid, data: data)
            } else {
                log("not matched message")
            }
        }
    }
    
    func executePromise(guid: String, data: String = "") {
        let execString = String(format: "promiseNativeCaller.executePromise('%@', %@)", guid, (data.isEmpty ? "undefined" : "'\(data)'"))
        debug(execString)
        self.webView.evaluateJavaScript(execString) {
            (data, err) in
            if let err = err {
                log("err: \(err)")
            }
        }
    }
    
    func setTheme(_ themeMode: String) {
        Theme.shared.setThemeMode(themeMode)
        Theme.shared.setManualMode(true)
        
        //        var window: UIWindow!
        //        if #available(iOS 15.0, *) {
        //            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        //                window = windowScene.windows.first
        //            }
        //        }
        //        guard #available(iOS 15.0, *) else {
        //            window = UIApplication.shared.windows.first
        //        }
        
        if themeMode == "light" {
            window.overrideUserInterfaceStyle = .light
        } else if themeMode == "dark" {
            window.overrideUserInterfaceStyle = .dark
        } else { // system
            window.overrideUserInterfaceStyle = .unspecified
        }
        defer {
            Theme.shared.setManualMode(false)
        }
        
//        setThemeWebViewController()
        // 변경 순서: window 스타일 변경 -> status bar 변경
//        debug("\(type(of: self))")
        debug("\(type(of: window.rootViewController!))")
        setThemeViewController(viewController: window.rootViewController!, themeMode: themeMode)
    }
    
    func setThemeWebViewController() {
        if let modalWebViewController = self as? ModalWebViewController {
            if [UIModalPresentationStyle.fullScreen, UIModalPresentationStyle.currentContext].contains(modalWebViewController.modalPresentationStyle) {
                self.view.backgroundColor = Theme.shared.getBackgroundColor()
            }
        } else {
            self.view.backgroundColor = Theme.shared.getBackgroundColor()
        }
        self.errorImageView?.tintColor = Theme.shared.getTabBarTintColor()
    }
    
    func setThemeViewController(viewController: UIViewController, themeMode: String, presented: Bool = false) {
        switch viewController {
        case let tabBarController as UITabBarController:
            //            tabBarController.viewControllers?.enumerated().forEach {
            changeTabBarAppearance(tabBarController);
            tabBarController.viewControllers?.forEach {
                debug("\(type(of: $0))")
                setThemeViewController(viewController: $0, themeMode: themeMode)
            }
            if let presentedViewController = tabBarController.presentedViewController {
                debug("\(type(of: presentedViewController))")
                setThemeViewController(viewController: presentedViewController, themeMode: themeMode, presented: true)
            }
        case let navigationController as UINavigationController:
            changeNavigationBarAppearance(navigationController.navigationBar)
            navigationController.viewControllers.forEach {
//                debug("\(type(of: $0))")
                setThemeViewController(viewController: $0, themeMode: themeMode)
            }
//            if let presentedViewController = navigationController.presentedViewController {
//                debug("\(type(of: presentedViewController))")
//                setThemeViewController(viewController: presentedViewController, themeMode: themeMode)
//            }
        default:
            guard viewController.isViewLoaded else {
                return
            }
            debug("\(type(of: viewController))")
            if let webViewController = viewController as? WebViewController, let webView = webViewController.webView {
                webViewController.setThemeWebViewController()
                if let customPushWebViewController = viewController as? CustomPushWebViewController {
                    changeNavigationBarAppearance(customPushWebViewController.navigationBar)
                } else if let modalWebViewController = viewController as? ModalWebViewController {
                    changeNavigationBarAppearance(modalWebViewController.navigationBar)
                }
                if self !== webViewController {
                    var preferThemeMode = themeMode
                    if preferThemeMode == "system" {
                        if Theme.shared.getUserInterfaceStyle() == .dark {
                            preferThemeMode = "dark"
                        } else {
                            preferThemeMode = "light"
                        }
                    }
                    let json: [String : Any] = [
                        "eventType": "theme",
                        "themeMode": themeMode,
                        "preferThemeMode": preferThemeMode
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: json), let value = String(data: data, encoding: .utf8) {
                        webView.postMessage(data: value)
                    }
                }
            }
            if presented, let presentedViewController = viewController.presentedViewController {
//                debug("\(type(of: presentedViewController)), \(type(of: presentedViewController.presentingViewController!))")
                setThemeViewController(viewController: presentedViewController, themeMode: themeMode, presented: presented)
            }
        }
    }
    
    func changeUserInterfaceStyle() {
        let themeMode = Theme.shared.getThemeMode()
        Theme.shared.setManualMode(true)
        if themeMode == "light" {
            window.overrideUserInterfaceStyle = .light
        } else if themeMode == "dark" {
            window.overrideUserInterfaceStyle = .dark
        } else { // system
            window.overrideUserInterfaceStyle = .unspecified
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            Theme.shared.setManualMode(false)
        }
        
        setThemeWebViewController()
        if let navigationBar = self.navigationController?.navigationBar {
            changeNavigationBarAppearance(navigationBar)
        }
        if let tabBarController = window.rootViewController as? UITabBarController {
            changeTabBarAppearance(tabBarController)
        }
    }
    
    func changeStatusBarBgColor(_ backgroundColor: UIColor?) {
        let statusBarManager = windowScene.statusBarManager
        let statusBarView = UIView(frame: statusBarManager?.statusBarFrame ?? .zero)
        statusBarView.backgroundColor = backgroundColor
        window.addSubview(statusBarView)
    }
    
    func changeNavigationBarAppearance(_ navigationBar: UINavigationBar?) {
        let appearance = UINavigationBarAppearance()
        //                appearance.configureWithOpaqueBackground()
        appearance.configureWithDefaultBackground()
        //                appearance.configureWithTransparentBackground()
        appearance.backgroundColor = Theme.shared.getNaviBarBackgroundColor()
        appearance.titleTextAttributes = [.foregroundColor: Theme.shared.getNaviBarTintColor(), .font: UIFont.systemFont(ofSize: CGFloat(20))]
        navigationBar?.tintColor = Theme.shared.getNaviBarTintColor()
        //        navigationBar?.barTintColor = Theme.shared.getNaviBarTintBackgroundColor(self)
        navigationBar?.standardAppearance = appearance
        navigationBar?.scrollEdgeAppearance = navigationBar?.standardAppearance
    }
    
    func changeTabBarAppearance(_ tabBarController: UITabBarController) {
        let appearance = UITabBarAppearance()
        //        appearance.configureWithOpaqueBackground()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = Theme.shared.getBackgroundColor()
        tabBarController.tabBar.tintColor = Theme.shared.getTabBarTintColor()
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = tabBarController.tabBar.standardAppearance
    }
    
    var windowScene: UIWindowScene {
        UIApplication.shared.connectedScenes.first as! UIWindowScene
    }
    
    var window: UIWindow {
        windowScene.windows.first!
    }
    
    func loginView(_ data: [String: Any]) {
        guard let from = data["from"] as? String else {
            return
        }
        guard self.window.rootViewController as? LoginViewController == nil else {
            debug("it is already a login view.")
            return
        }
        
        UserInformation.shared.clearLoginInfo()
        if from != "/" {
            var locationData: [String: Any] = ["location" : from]
            if let viewInfo = data["viewInfo"] as? [String: Any] {
                locationData["viewInfo"] = viewInfo
            }
            UserInformation.shared.locations.insert(locationData, at: 0)
        }
        
        let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: .main)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        if let sceneDelegate = windowScene.delegate as? SceneDelegate {
            sceneDelegate.changeRootVC(loginViewController, animated: true)
        }
    }
    
    func navigateView(_ data: [String: Any]) {
        guard let location = data["location"] as? String else {
            return
        }
        
        var path = location
        if let searchIndex = location.firstIndex(of: "?") {
            path = String(location[location.startIndex..<searchIndex])
        }
        //        var pushNtfcPt: String?
        //        if let range: Range<String.Index> = location.range(of: "pushNtfcPt=") {
        //            //let startIndex: Int = location.distance(from: location.startIndex, to: range.upperBound)
        //            //pushNtfcPt = location[startIndex..<location.count]
        //            pushNtfcPt = String(location[range.upperBound..<location.endIndex]) // Substring
        //        }
        debug("location: \(location), path: \(path)")
                
        var isTabView = true
        if AppEnvironment.centPageURL.absoluteString.hasSuffix(path) {
            self.tabBarController?.selectedIndex = 0
        } else if AppEnvironment.mainPageURL.absoluteString.hasSuffix(path) {
            self.tabBarController?.selectedIndex = 1
        } else if AppEnvironment.trcnPageURL.absoluteString.hasSuffix(path) {
            self.tabBarController?.selectedIndex = 2
        } else {
            isTabView = false
            // shorter: 200, short: 250, standard: 300
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                if UserInformation.shared.loginInfo != nil {
                    if location.contains("viewMode=modal") {
                        self?.modalView(data)
                    } else {
                        self?.pushView(data)
                    }
                } else { // logout 상태라면
                    let locationData: [String: Any] = ["location": location]
                    UserInformation.shared.locations.append(locationData)
                }
            }
        }
        if isTabView, let navigationController = self.tabBarController?.selectedViewController as? TabNavigationController {
            navigationController.popToRootViewController(animated: true)
            if let webViewController = navigationController.topViewController as? WebViewController {
                webViewController.reloadWebPage()
            }
        }
    }
    
    func modalView(_ data: [String: Any]) {
        guard var location = data["location"] as? String else {
            return
        }
        
        let modalViewControlller = ModalWebViewController()
        //modalViewControlller.hidesBottomBarWhenPushed = true
        if location.hasPrefix("/") {
            location = .init(location.dropFirst())
        }
        modalViewControlller.location = location
        if let viewInfo = data["viewInfo"] as? [String: Any] {
            modalViewControlller.viewInfo = viewInfo
            
            if let presentationStyle = viewInfo["presentationStyle"] as? String {
                switch presentationStyle {
                case "full":
                    modalViewControlller.modalPresentationStyle = .fullScreen
                case "context":
                    modalViewControlller.modalPresentationStyle = .currentContext
                case "overFull":
                    modalViewControlller.modalPresentationStyle = .overFullScreen
                case "overContext":
                    modalViewControlller.modalPresentationStyle = .overCurrentContext
                default:
                    modalViewControlller.modalPresentationStyle = .automatic
                }
            }
            
            if let transitionStyle = viewInfo["transitionStyle"] as? String {
                switch transitionStyle {
                case "dissolve":
                    modalViewControlller.modalTransitionStyle = .crossDissolve
                default:
                    modalViewControlller.modalTransitionStyle = .coverVertical
                }
            }
        }
        
        present(modalViewControlller, animated: true)
    }
    
    func pushView(_ data: [String: Any]) {
        guard var location = data["location"] as? String else {
            return
        }
        
        let popupViewControlller = PushWebViewController()
        popupViewControlller.hidesBottomBarWhenPushed = true
        if location.hasPrefix("/") {
            location = .init(location.dropFirst())
        }
        popupViewControlller.location = location
        if let viewInfo = data["viewInfo"] as? [String: Any] {
            popupViewControlller.viewInfo = viewInfo
        }
        
        if let navigationController = self.navigationController {
            navigationController.pushViewController(popupViewControlller, animated: true)
        } else if let tabBarController = self.presentingViewController as? UITabBarController, let navigationController = tabBarController.viewControllers?[tabBarController.selectedIndex] as? UINavigationController {
            self.dismiss(animated: false) {
                navigationController.pushViewController(popupViewControlller, animated: true)
            }
        }
    }
    
    func setViewInfo(viewInfo: [String: Any]) {
        guard let popupViewControlller = self as? PushWebViewController else {
            return
        }
        
        popupViewControlller.setViewInfo(viewInfo)
    }
    
    @objc func goBack() {
        if self.presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func loggedOut() {
        guard UserInformation.shared.loginInfo != nil else {
            debug("it was already logged out.")
            return
        }
        UserInformation.shared.clearLoginInfo()
        Theme.shared.setThemeMode(nil)
        let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: .main)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        if let sceneDelegate = windowScene.delegate as? SceneDelegate {
            sceneDelegate.changeRootVC(loginViewController, animated: true)
        }
    }
}

struct AppInfo: Codable {
    var moappNm: String
    var mblInhrIdnnVal: String
    var deviceModel: String
    var mblOsKndCd = "I"
    var mbphOsVer: String
    var moappVerCd: String
    var moappVer: String
    var pushTknVal: String?
    
    static func getAppInfo() -> AppInfo {
        return AppInfo(moappNm: GmmApplication.shared.getAppName(),
                       mblInhrIdnnVal: DeviceInformation.shared.getDeviceId(),
                       deviceModel: DeviceInformation.shared.getDeviceModel(),
                       mbphOsVer: String(format: "iOS %@", DeviceInformation.shared.getOsVersion()),
                       moappVerCd: DeviceInformation.shared.getAppVersionCode(),
                       moappVer: DeviceInformation.shared.getAppVersionName(),
                       pushTknVal: DeviceInformation.shared.getRegistrationToken())
    }
}

class GUIDLocationManager: CLLocationManager {
    var guid: String
    var completion: (CLLocation?) -> Void
    
    init(guid: String, completion: @escaping (CLLocation?) -> Void) {
        self.guid = guid
        self.completion = completion
        super.init()
    }
    
    func isPermission() -> Bool {
        if [.restricted, .notDetermined, .denied].contains(self.authorizationStatus) {
            return false
        } else {
            return true
        }
    }
}

struct Theme {
    static let shared = Theme()
    
    let textLightColor: UIColor = .white
    let textDarkColor: UIColor = .init(hexCode: "#FFFFFF", alpha: 0.7)
    let lightBackground: UIColor = .white
    let darkBackground: UIColor = .init(hexCode: "#121212")
    let lightBackground2: UIColor = .white
    let darkBackground2: UIColor = .init(hexCode: "#424242")
    let tabBarLightTintColor: UIColor = .init(hexCode: "#9c27b0")
    let tabBarDarkTintColor: UIColor = .init(hexCode: "#ce93d8")
    let naviBarLightBackground: UIColor = .init(hexCode: "#9c27b0")
    let naviBarLightTintBackground: UIColor = .init(hexCode: "#9c27b0")
    let naviBarDarkBackground: UIColor = .init(hexCode: "#121212")
    let naviBarDarkTintBackground: UIColor = .init(hexCode: "#121212", alpha: 0.215)
    let naviBarLightTintColor: UIColor = .white
    let naviBarDarkTintColor: UIColor = .init(hexCode: "#ce93d8")
    let subTitleLightColor: UIColor = .init(hexCode: "#ffe0b2")
    let subTitleDarkColor: UIColor = .init(hexCode: "#ffa726", alpha: 0.8)
    let primaryLightBackground: UIColor = .init(hexCode: "#1976d2")
    let primaryDarkBackground: UIColor = .init(hexCode: "#90caf9")
    let secondaryLightBackground: UIColor = .init(hexCode: "#9c27b0")
    let secondaryDarkBackground: UIColor = .init(hexCode: "#ce93d8")
    let errorLightBackground: UIColor = .init(hexCode: "#d32f2f")
    let errorDarkBackground: UIColor = .init(hexCode: "#f44336")
    let successLightBackground: UIColor = .init(hexCode: "#2e7d32")
    let successDarkBackground: UIColor = .init(hexCode: "#66bb6a")
    let warningLightBackground: UIColor = .init(hexCode: "#ed6c02")
    let warningDarkBackground: UIColor = .init(hexCode: "#ffa726")
    let infoLightBackground: UIColor = .init(hexCode: "#0288d1")
    let infoDarkBackground: UIColor = .init(hexCode: "#81d4fa")
    
    
    private init() {
    }
    
    func getTextColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return textLightColor
        } else {
            return textDarkColor
        }
    }
    
    func getBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return lightBackground
        } else {
            return darkBackground
        }
    }
    
    func getBackgroundColor2() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return lightBackground2
        } else {
            return darkBackground2
        }
    }
    
    func getTabBarTintColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return tabBarLightTintColor
        } else {
            return tabBarDarkTintColor
        }
    }
    
    func getNaviBarBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return naviBarLightBackground
        } else {
            return naviBarDarkBackground
        }
    }
    
    func getNaviBarTintBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return naviBarLightTintBackground
        } else {
            return naviBarDarkTintBackground
        }
    }
    
    //    func getNaviBarTintBackgroundColor(_ viewController: UIViewController, alpha: CGFloat) -> UIColor {
    //        if getUserInterfaceStyle() == .light {
    //            return .init(hexCode: "#9c27b0", alpha: alpha)
    //        } else {
    //            return .init(hexCode: "#121212", alpha: alpha)
    //        }
    //    }
    
    func getNaviBarTintColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return naviBarLightTintColor
        } else {
            return naviBarDarkTintColor
        }
    }
    
    func getSubTitleColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return subTitleLightColor
        } else {
            return subTitleDarkColor
        }
    }
    
    func getBackgroundColor(color: String) -> UIColor {
        switch color {
        case "primary":
            return getPrimaryBackgroundColor()
        case "secondary":
            return getSecondaryBackgroundColor()
        case "error":
            return getErrorBackgroundColor()
        case "success":
            return getSuccessBackgroundColor()
        case "warning":
            return getWarningBackgroundColor()
        case "info":
            return getInfoBackgroundColor()
        case "back2":
            return getBackgroundColor2()
        default:
            return getBackgroundColor()
        }
    }
    
    func getPrimaryBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return primaryLightBackground
        } else {
            return primaryDarkBackground
        }
    }
    
    func getSecondaryBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return secondaryLightBackground
        } else {
            return secondaryDarkBackground
        }
    }
    
    func getErrorBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return errorLightBackground
        } else {
            return errorDarkBackground
        }
    }
    
    func getSuccessBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return successLightBackground
        } else {
            return successDarkBackground
        }
    }
    
    func getWarningBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return warningLightBackground
        } else {
            return warningDarkBackground
        }
    }
    
    func getInfoBackgroundColor() -> UIColor {
        if getUserInterfaceStyle() == .light {
            return infoLightBackground
        } else {
            return infoDarkBackground
        }
    }
    
    func getUserInterfaceStyle() -> UIUserInterfaceStyle {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        if windowScene.windows.first?.overrideUserInterfaceStyle == .unspecified {
            return windowScene.windows.first!.rootViewController!.traitCollection.userInterfaceStyle
        } else {
            return windowScene.windows.first!.overrideUserInterfaceStyle
        }
    }
    
    func getThemeMode() -> String {
        return UserDefaults.standard.string(forKey: "themeMode") ?? "system"
    }
    
    func setThemeMode(_ themeMode: String?) {
        UserDefaults.standard.set(themeMode, forKey: "themeMode")
    }
    
    func setManualMode(_ manualMode: Bool) {
        UserDefaults.standard.set(manualMode, forKey: "manualMode")
    }
    
    func isManualMode() -> Bool {
        UserDefaults.standard.bool(forKey: "manualMode")
    }
}
