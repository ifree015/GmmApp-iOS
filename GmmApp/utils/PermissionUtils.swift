//
//  PermissionUtils.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation
import CoreLocation

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
    
    static func requestLocationPermission(delegate: CLLocationManagerDelegate) -> CLLocationManager {
        let locationManger = CLLocationManager();
        locationManger.delegate = delegate
        locationManger.requestWhenInUseAuthorization()
        return locationManger
     }
}

