//
//  LoginService.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/18.
//

import Foundation

struct LoginService {
    static let shared = LoginService()
    
    private init() {
    }
    
    func fetchAutoLogin(completion: @escaping (Result<[String: Any], Error>) -> ()) {
        var payload: [String: String] = [:]
        payload["moappNm"] = GmmApplication.shared.getAppName()
        payload["mblInhrIdnnVal"] = DeviceInformation.shared.getDeviceId()
        payload["deviceModel"] = DeviceInformation.shared.getDeviceModel()
        payload["mblOsKndCd"] = "I"
        payload["mbphOsVer"] = String(format: "iOS %@", DeviceInformation.shared.getOsVersion())
        payload["moappVerCd"] = DeviceInformation.shared.getAppVersionCode()
        payload["moappVer"] = DeviceInformation.shared.getAppVersionName()
        payload["pushTknVal"] = DeviceInformation.shared.getRegistrationToken()
        
        //        do {
        //            CookieUtils.setAuthTokens()
        //            try FetchAPI.shared.fetchFormUrlencoded(path: "user/AutoLogin.ajax", payload: payload, completion: completion)
        //        } catch {
        //            log("error: \(String(describing: error))")
        //            completion(.failure(error))
        //        }
        CookieUtils.setAuthTokens()
        FetchAPI.shared.fetchFormUrlencoded(path: "user/AutoLogin.ajax", payload: payload, timeout: 5, completion: completion)
    }
}
