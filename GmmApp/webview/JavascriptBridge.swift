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
    static let deviceInfo = DeviceInformation()
    static let userInfo = UserInformation()
    
    static func createWKUserContentController(messageHandler: WKScriptMessageHandler) -> WKUserContentController {
        let userContentController = WKUserContentController()
        userContentController.add(messageHandler, name: "showWebView")
        userContentController.add(messageHandler, name: "getAppName")
        userContentController.add(messageHandler, name: "getAppInfo")
        userContentController.add(messageHandler, name: "isPermission")
        userContentController.add(messageHandler, name: "getLastKnownLocation")
        userContentController.add(messageHandler, name: "setThemeMode")
        userContentController.add(messageHandler, name: "showToastMessage")
        
#if DEBUG
        let source = "function captureLog(msg) { window.webkit.messageHandlers.consoleLog.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        userContentController.add(ConsoleLogHandler(), name: "consoleLog")
#endif
        return userContentController
    }
}

class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        debugPrint("consoleLog: \(message.body)")
    }
}

extension ViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let data = message.body as? [String: Any], let guid = data["guid"] as? String else {
            return
        }
        debug("messageName: \(message.name), data: \(data)")
        
        switch message.name {
        case "showWebView":
            if self.webView.isHidden {
                let delayTime = 0.25
//                if let appDelegate = UIApplication.shared.delegate as? AppDelegate, !appDelegate.isShowed {
//                    appDelegate.isShowed = true
//                    delayTime = 0.25
//                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    self.showWebView()
                }
            }
            //        case "initWeb":
            //            initWeb()
        case "getAppName":
            executePromise(guid: guid, data: "GmmApp")
        case "getAppInfo":
            let appInfo: AppInfo = .init(mblInhrIdnnVal: JavascriptBridge.deviceInfo.getDeviceId(),
                                         deviceModel: JavascriptBridge.deviceInfo.getDeviceModel(),
                                         mbphOsVer: String(format: "iOS %@", JavascriptBridge.deviceInfo.getOsVersion()),
                                         moappVerCd: JavascriptBridge.deviceInfo.getAppVersionCode(),
                                         moappVer: JavascriptBridge.deviceInfo.getAppVersionName(),
                                         pushTknVal: JavascriptBridge.deviceInfo.getRegistrationToken())
            do {
                let jsonData = try JSONEncoder().encode(appInfo)
                executePromise(guid: guid, data: String(data: jsonData, encoding: .utf8)!)
            } catch {
                log(error.localizedDescription)
                executePromise(guid: guid)
            }
            
        case "getPhoneNumber":
            executePromise(guid: guid, data: JavascriptBridge.userInfo.getPhoneNumber() ?? "")
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
                    self.view.makeToast("It is not location permission!")
                    self.executePromise(guid: guid)
                }
            })
            if guidLocationManager.isPermission() {
                guidLocationManager.delegate = self
                guidLocationManager.desiredAccuracy = kCLLocationAccuracyBest
                //                guidLocationManager.requestWhenInUseAuthorization()
                guidLocationManager.startUpdatingLocation()
                self.locationManagers.updateValue(guidLocationManager, forKey: guid)
            }
        case "setThemeMode":
            guard let mode = data["data"] as? String else {return}
            debug("mode: \(mode)")
            UserDefaults.standard.set(mode, forKey: "Appearance")
            self.changeUserInterfaceStyle()
        case "showToastMessage":
            debug("\(data["data"]!)")
            if let message = data["data"] as? String {
                self.view.makeToast(message)
            }
        default:
            log("not matched message")
        }
    }
    
    func showWebView() {
        if (self.webView.isHidden) {
            self.changeUserInterfaceStyle()
            self.launch.isHidden = true
//            self.launch.removeFromSuperview()
            self.brand.isHidden = true
//            self.brand.removeFromSuperview()
            self.webView.isHidden = false
//            UIView.transition(with: self.webView, duration: 0.25,
//                              options: .transitionCrossDissolve,
//                              animations: {
//                self.webView.alpha = 1
//            })
        }
    }
    
    //    func initWeb() {
    //        guard toLocation.count > 0 else {
    //            return
    //        }
    //        debug("\(toLocation)")
    //        let json: [String: Any] = [
    //            "eventType": "navigate",
    //            "toLocation": toLocation,
    //        ]
    //        defer {
    //            toLocation = ""
    //        }
    //        do {
    //            let jsonData = try JSONSerialization.data(withJSONObject: json)
    //            self.webView.postMessage(data: String(data: jsonData, encoding: .utf8)!)
    //        } catch {
    //            log(error.localizedDescription)
    //        }
    //    }
    
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
    
    func changeUserInterfaceStyle() {
        guard let appearance = UserDefaults.standard.string(forKey: "Appearance") else { return }
        
        var window: UIWindow!
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                window = windowScene.windows.first
            }
        }
        guard #available(iOS 15.0, *) else {
            window = UIApplication.shared.windows.first
        }
        
        if appearance == "light" {
            window.overrideUserInterfaceStyle = .light
            self.view.backgroundColor = UIColor.white
        } else if appearance == "dark" {
            window.overrideUserInterfaceStyle = .dark
            self.view.backgroundColor = UIColor(red: 18, green: 18, blue: 18) // #121212
        } else { // system
            window.overrideUserInterfaceStyle = .unspecified
            if self.traitCollection.userInterfaceStyle == .dark {
                self.view.backgroundColor = UIColor(red: 18, green: 18, blue: 18)
            } else {
                self.view.backgroundColor = UIColor.white
            }
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
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1)
    }
}
