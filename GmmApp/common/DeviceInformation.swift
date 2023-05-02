//
//  DeviceInformation.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation
import UIKit

struct DeviceInformation {
    
    func getDeviceId() -> String {
        // udid(40 -> 24) -> uuid(36: 32/4)
        return UIDevice.current.identifierForVendor!.uuidString
    }
    
    func getDeviceModel() -> String {
        // 1. 시뮬레이터 체크 수행
        if let modelName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"], modelName.count > 0 { // iPhone 14 Pro
            return modelName
        }
        
        // 2. 실제 디바이스 체크 수행
        let device = UIDevice.current
        let selName = "_\("deviceInfo")ForKey:"
        let selector = NSSelectorFromString(selName)
        if device.responds(to: selector) {
            return String(describing: device.perform(selector, with: "marketing-name").takeUnretainedValue())
        }
        return UIDevice.current.model
    }
    
    func getOsVersion() -> String {
        return UIDevice.current.systemVersion // 16.2
    }
    
    func getAppVersionCode() -> String {
        if let info: [String: Any] = Bundle.main.infoDictionary, let buildNumber: String = info["CFBundleVersion"] as? String {
            return buildNumber
        }
        return ""
    }
    
    func getAppVersionName() -> String {
        if let info = Bundle.main.infoDictionary, let version = info["CFBundleShortVersionString"] as? String {
            return version
        }
        return ""
    }
    
    func getRegistrationToken() -> String? {
        return UserDefaults.standard.string(forKey: "RegistrationToken")
    }
}
