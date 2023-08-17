//
//  UserInformation.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation
import CoreLocation

struct UserInformation {
    
    static var shared = UserInformation()

    var loginInfo: LoginInfo?
    var from: String?
    var fromViewInfo: [String: Any]?
    var toLocation: String?
        
    private init() {
    }
    
    func getPhoneNumber() -> String? {
        // unattainable
        return nil
    }
    
    func getLastKnownLocation() -> CLLocation? {
        // 동기적으로 얻을 방법 없음
        return nil
    }
        
    func isAutoLogin() -> Bool {
        return UserDefaults.standard.bool(forKey: "autoLogin")
    }
    
    func setAutoLogin(_ autoLogin: Bool) {
        UserDefaults.standard.set(autoLogin, forKey: "autoLogin")
    }
    
    mutating func clearInfo() {
        self.loginInfo = nil
        self.from = nil
        self.fromViewInfo = nil
        self.toLocation = nil
        setAutoLogin(false)
    }
}

struct LoginInfo {
    var accessToken: String
    var refreshToken: String
    var appTimeout: Int
    var userInfo: [String: Any]
}
