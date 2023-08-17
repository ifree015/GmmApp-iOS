//
//  JavascriptBridge.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation
import WebKit
import CoreLocation

let commonProcessPool = WKProcessPool()

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
        userContentController.add(webViewController, name: "pushView")
        userContentController.add(webViewController, name: "setViewInfo")
        userContentController.add(webViewController, name: "goBack")
        userContentController.add(webViewController, name: "navigateView")
        userContentController.add(webViewController, name: "loggedOut")
        
        if let bridge = webViewController as? WebViewBridge {
            bridge.addMessageHandlers(userContentController)
        }
        
        if let userInfo = UserInformation.shared.loginInfo?.userInfo, let data = try? JSONSerialization.data(withJSONObject: userInfo), let value = String(data: data, encoding: .utf8) {
            //            debug("\(value)")
            let script = WKUserScript(
                source: "window.sessionStorage.setItem('userInfo', '\(value)');",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContentController.addUserScript(script)
        }
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
}

protocol WebViewBridge {
    func addMessageHandlers(_ userContentController: WKUserContentController)
    func handleMessages(messageName: String, guid: String, data: [String: Any])
}

class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        debugPrint("consoleLog: \(message.body)")
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
        case "pushView":
            self.pushView(data["data"] as! [String: Any])
        case "setViewInfo":
            self.setViewInfo(viewInfo: data["data"] as! [String: Any])
        case "goBack":
            self.goBack()
        case "navigateView":
            self.navigateView(data["data"] as! [String: Any])
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
        self.view.backgroundColor = Theme.shared.getBackgroundColor(self)
        // 변경 순서: window 스타일 변경 -> status bar 변경
        debug("\(type(of: self))")
        
        setThemeViewController(viewController: window.rootViewController!, themeMode: themeMode)
    }
    
    func setThemeViewController(viewController: UIViewController, themeMode: String) {
        switch viewController {
        case let tabBarController as UITabBarController:
            //            tabBarController.viewControllers?.enumerated().forEach {
            changeTabBarAppearance(tabBarController);
            tabBarController.viewControllers?.forEach {
                //                if tabBarController.selectedIndex == $0 {
                //                    return
                //                }
                setThemeViewController(viewController: $0, themeMode: themeMode)
            }
        case let navigationController as UINavigationController:
            navigationController.viewControllers.forEach {
                setThemeViewController(viewController: $0, themeMode: themeMode)
            }
            if let visibleViewController = navigationController.visibleViewController, navigationController.topViewController !== visibleViewController {
                setThemeViewController(viewController: visibleViewController, themeMode: themeMode)
            }
        default:
            if !viewController.isViewLoaded || self === viewController {
                return
            }
            viewController.view.backgroundColor = Theme.shared.getBackgroundColor(viewController)
            if let webViewController = viewController as? WebViewController, let webView = webViewController.webView {
                var preferThemeMode = themeMode
                if preferThemeMode == "system" {
                    if Theme.shared.getUserInterfaceStyle(webViewController) == .dark {
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
    }
    
    func changeUserInterfaceStyle(_ initialViewController: Bool = false) {
        if initialViewController, let themeMode = Theme.shared.getThemeMode() {
            if themeMode == "light" {
                window.overrideUserInterfaceStyle = .light
            } else if themeMode == "dark" {
                window.overrideUserInterfaceStyle = .dark
            } else { // system
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
        self.view.backgroundColor = Theme.shared.getBackgroundColor(self)
        
        if initialViewController, let tabBarController = window.rootViewController as? UITabBarController {
            changeTabBarAppearance(tabBarController)
        }
    }
    
    func changeTabBarAppearance(_ tabBarController: UITabBarController?) {
        let appearance = UITabBarAppearance()
        //        appearance.configureWithOpaqueBackground()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = Theme.shared.getBackgroundColor(self)
        tabBarController?.tabBar.tintColor = Theme.shared.getTabBarTintColor(self)
        tabBarController?.tabBar.standardAppearance = appearance
        tabBarController?.tabBar.scrollEdgeAppearance = tabBarController?.tabBar.standardAppearance
    }
    
    func changeNavigationBarAppearance(_ navigationBar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
        appearance.configureWithDefaultBackground()
//        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = Theme.shared.getNaviBarBackgroundColor(self)
        appearance.titleTextAttributes = [.foregroundColor: Theme.shared.getNaviBarTintColor(self), .font: UIFont.systemFont(ofSize: CGFloat(20))]
        navigationBar.tintColor = Theme.shared.getNaviBarTintColor(self)
        navigationBar.barTintColor = Theme.shared.getNaviBarTintBackgroundColor(self)
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
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
        
        UserInformation.shared.clearInfo()
        UserInformation.shared.from = from
        if let viewInfo = data["viewInfo"] as? [String: Any] {
            UserInformation.shared.fromViewInfo = viewInfo
        }
        
        let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "LoginViewController")
        if let sceneDelegate = windowScene.delegate as? SceneDelegate {
            sceneDelegate.changeRootVC(loginViewController, animated: true)
        }
    }
    
    func pushView(_ data: [String: Any]) {
        guard var location = data["location"] as? String else {
            return
        }
        
        let popupViewControlller = PushViewController()
        popupViewControlller.hidesBottomBarWhenPushed = true
        if location.hasPrefix("/") {
            location = .init(location.dropFirst())
        }
        popupViewControlller.location = location
        if let viewInfo = data["viewInfo"] as? [String: Any] {
            popupViewControlller.viewInfo = viewInfo
        }
        
        //        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(popupViewControlller, animated: true)
    }
    
    func setViewInfo(viewInfo: [String: Any]) {
        guard let popupViewControlller = self as? PushViewController else {
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
    
    func navigateView(_ data: [String: Any]) {
        guard let location = data["location"] as? String else {
            return
        }
        
        var pathname = location
        if let searchIndex = location.firstIndex(of: "?") {
            pathname = String(location[location.startIndex..<searchIndex])
        }
        debug("location: \(location), pathname: \(pathname)")
        
        var isTabView = true
        if AppEnvironment.centPageURL.absoluteString.hasSuffix(pathname) {
            self.tabBarController?.selectedIndex = 0
        } else if AppEnvironment.mainPageURL.absoluteString.hasSuffix(pathname) {
            self.tabBarController?.selectedIndex = 1
        } else if AppEnvironment.trcnPageURL.absoluteString.hasSuffix(pathname) {
            self.tabBarController?.selectedIndex = 2
        } else {
            isTabView = false
            pushView(data)
        }
        if isTabView, let navigationController = self.tabBarController?.selectedViewController as? TabNavigationController {
            navigationController.popToRootViewController(animated: true)
            if let webViewController = navigationController.topViewController as? WebViewController {
                webViewController.reloadWebPage()
            }
        }
    }
    
    func loggedOut() {
        UserInformation.shared.clearInfo()
        let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "LoginViewController")
        if let sceneDelegate = windowScene.delegate as? SceneDelegate {
            sceneDelegate.changeRootVC(loginViewController, animated: true)
        }
    }
}

struct AppInfo: Codable {
    var mblInhrIdnnVal: String
    var deviceModel: String
    var mblOsKndCd = "I"
    var mbphOsVer: String
    var moappVerCd: String
    var moappVer: String
    var pushTknVal: String?
    
    static func getAppInfo() -> AppInfo {
        return AppInfo(mblInhrIdnnVal: DeviceInformation.shared.getDeviceId(),
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

extension UIColor {
    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
    }
    
    convenience init(hexCode: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hexCode.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

struct Theme {
    static let shared = Theme()
    
    let lightBackground: UIColor = .white
    let darkBackground: UIColor = .init(hexCode: "#121212")
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
    
    private init() {
    }
    
    func getBackgroundColor(_ viewController: UIViewController) -> UIColor {
        if getUserInterfaceStyle(viewController) == .light {
            return lightBackground
        } else {
            return darkBackground
        }
    }
    
    func getTabBarTintColor(_ viewController: UIViewController) -> UIColor {
        if getUserInterfaceStyle(viewController) == .light {
            return tabBarLightTintColor
        } else {
            return tabBarDarkTintColor
        }
    }
    
    func getNaviBarBackgroundColor(_ viewController: UIViewController) -> UIColor {
        if getUserInterfaceStyle(viewController) == .light {
            return naviBarLightBackground
        } else {
            return naviBarDarkBackground
        }
    }
    
    func getNaviBarTintBackgroundColor(_ viewController: UIViewController) -> UIColor {
        if getUserInterfaceStyle(viewController) == .light {
            return naviBarLightTintBackground
        } else {
            return naviBarDarkTintBackground
        }
    }
    
    func getNaviBarTintColor(_ viewController: UIViewController) -> UIColor {
        if getUserInterfaceStyle(viewController) == .light {
            return naviBarLightTintColor
        } else {
            return naviBarDarkTintColor
        }
    }
    
    func getSubTitleColor(_ viewController: UIViewController) -> UIColor {
        if getUserInterfaceStyle(viewController) == .light {
            return subTitleLightColor
        } else {
            return subTitleDarkColor
        }
    }
    
    func getUserInterfaceStyle(_ viewController: UIViewController) -> UIUserInterfaceStyle {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        if windowScene.windows.first?.overrideUserInterfaceStyle == .unspecified {
            return viewController.traitCollection.userInterfaceStyle
        } else {
            return windowScene.windows.first!.overrideUserInterfaceStyle
        }
    }
    
    func getThemeMode() -> String? {
        return UserDefaults.standard.string(forKey: "themeMode")
    }
    
    func setThemeMode(_ themeMode: String) {
        UserDefaults.standard.set(themeMode, forKey: "themeMode")
    }
}

extension String {
    
    subscript(_ index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    subscript(_ range: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let toIndex = self.index(self.startIndex,offsetBy: range.endIndex)
        return String(self[fromIndex..<toIndex])
    }
}
