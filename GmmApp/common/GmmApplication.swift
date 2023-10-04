//  
//  GmmApplication.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/17.
//

import UserNotifications
import CoreLocation
import Toast_Swift

class GmmApplication: NSObject {
    
    static let shared = GmmApplication()
    
    var initialized: Bool = false
    var uiInitialized: Bool = false
    var locationManager: CLLocationManager!
        
    func getAppName() -> String {
        return "GmmApp"
    }
    
    override private init() {
        super.init()
    }
    
    func initialize() {
        debug("initialize")
        guard !initialized else {
            return
        }
        self.initialized = true
        
        // 1. 최초 실행이라면
        if !UserDefaults.standard.bool(forKey: "firstRunning") {
            UserDefaults.standard.set(true, forKey: "firstRunning")
            
            // 2. remote notification 초기화
            initPushNotification()
            
            // 3. location manager 초기화
            initLocationManager()
        } else {
            //            if !PermissionUtils.hasPermissions(permissions: "location") {
            //                viewControlller.view.makeToast("일부 권한이 허용되지 않았습니다!")
            //            }
        }
        // 4. push notification observer 등록
        NotificationCenter.default.addObserver(self, selector: #selector(didRecievePushNotification(_:)), name: NSNotification.Name.pushNotification, object: nil)
    }
    
    func uiInitialize(_ viewController: UIViewController) {
        guard !uiInitialized else {
            return
        }
        self.uiInitialized = true
        
        // 1. init toast
        initToast()
    }
    
    func initPushNotification() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            log("UserNotification granted: \(granted)")
            if let error = error {
                log("Error: \(error)")
            }
            guard granted else { return }
            
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @objc func didRecievePushNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        debug("userInfo: \(userInfo)")
        
        guard var toLocation = userInfo["cnctMoappScrnVal"] as? String else {
            return
        }
        if let query = userInfo["ntgtVal"] as? String {
            toLocation = toLocation + "?" + query
        }
        if let pushNtfcPt = userInfo["pushNtfcPt"] as? String {
            if toLocation.contains("?") {
                toLocation += "&pushNtfcPt=\(pushNtfcPt)"
            } else {
                toLocation += "?pushNtfcPt=\(pushNtfcPt)"
            }
        }
        debug("toLocation: \(toLocation)")
        
        if UserInformation.shared.loginInfo != nil {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first else {
                return
            }
            let data: [String: Any] = ["location": toLocation]
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            //                if UserInformation.shared.loginInfo != nil {
            if let webViewController = window.rootViewController as? WebViewController {
                webViewController.navigateView(data)
            } else if let tabBarController = window.rootViewController as? UITabBarController, let navigationController = tabBarController.selectedViewController as? UINavigationController, let webViewController = navigationController.topViewController as? WebViewController {
                webViewController.navigateView(data)
            }
            let badgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
            if  badgeNumber >= 0 {
                UIApplication.shared.applicationIconBadgeNumber = badgeNumber
            }
            //                } else {
            //                    UserInformation.shared.toLocation = toLocation
            //                }
            //            }
        } else {
            let locationData: [String: Any] = ["location": toLocation]
            UserInformation.shared.locations.append(locationData)
        }
    }
    
    /// GmmApplication.shared.sendNotification(title: "test", body: "test")
    func sendNotification(title: String, body: String, seconds: Double = 0.3) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            guard let error = error else { return }
            log(error.localizedDescription)
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
}

extension GmmApplication: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        debug("locationManger: \(manager)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        if let location = locations.last  {
            debug("\(location)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debug("errored: \(error)")
    }
}
