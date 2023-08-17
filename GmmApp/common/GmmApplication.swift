//  
//  GmmApplication.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/17.
//

import CoreLocation
import Toast_Swift

class GmmApplication: NSObject {
        
    static let shared = GmmApplication()
    
    var initialized: Bool = false
    var locationManager: CLLocationManager!
    
    override private init() {
        super.init()
    }
    
    func initialize(_ viewController: UIViewController) {
        if initialized {
            return
        }
        self.initialized = true
        
        // 1. init toast
        initToast()
        
        // 3. 최초 실행이라면
        if !UserDefaults.standard.bool(forKey: "firstRunned") {
            UserDefaults.standard.set(true, forKey: "firstRunned")
            initLocationManager()
        } else {
//            if !PermissionUtils.hasPermissions(permissions: "location") {
//                viewControlller.view.makeToast("일부 권한이 허용되지 않았습니다!")
//            }
        }
    }
    
    private func initToast() {
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
    
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
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
