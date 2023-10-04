//
//  PermissionUtils.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation
import CoreLocation
import UserNotifications

struct PermissionUtils {
    static func hasPermissions(permissions: String...) -> Bool {
        for permission in permissions {
            switch permission {
            case "location":
                guard isLocationPermission() else {
                    return false
                }
            default:
                return false
            }
        }
        
        return true
    }
    
    @discardableResult
    static func requestPushNotificationPermission(completion: @escaping (Bool) -> Void) -> UNUserNotificationCenter {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: authOptions) { granted, error in
            log("UserNotification granted: \(granted)")
            if let error = error {
                log("Error: \(error)")
            }
            completion(granted)
        }
        
        return center
     }
    
    static func isPushNotificationPermission(completion: @escaping (Bool) -> Void)  {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                debug("authorized")
                //      case .denied:
                //        debug("denied")
                //      case .notDetermined:
                //        debug("not determined, ask user for permission now")
                return completion(true)
            default:
                return completion(false)
            }
        })
    }
    
    @discardableResult
    static func requestLocationPermission(delegate: CLLocationManagerDelegate) -> CLLocationManager {
        let locationManger = CLLocationManager();
        locationManger.delegate = delegate
        locationManger.requestWhenInUseAuthorization()
        return locationManger
     }
    
    static func isLocationPermission() -> Bool {
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14, *) {
            authorizationStatus = CLLocationManager().authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        if [.restricted, .notDetermined, .denied].contains(authorizationStatus) {
            return false
        }
        return true
    }
}

