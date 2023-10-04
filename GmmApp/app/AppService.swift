//
//  AppService.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/22.
//

import Foundation

struct AppService {
    static let shared = AppService()
    
    private init() {
    }
    
    func fetchLstAppVer(completion: @escaping (Result<[String: Any], Error>) -> ()) {
        var payload: [String: String] = [:]
        payload["moappNm"] = GmmApplication.shared.getAppName()
//        payload["mblInhrIdnnVal"] = DeviceInformation.shared.getDeviceId()
//        payload["deviceModel"] = DeviceInformation.shared.getDeviceModel()
        payload["mblOsKndCd"] = "I"
//        payload["mbphOsVer"] = String(format: "iOS %@", DeviceInformation.shared.getOsVersion())
        payload["moappVerCd"] = DeviceInformation.shared.getAppVersionCode()
        payload["moappVer"] = DeviceInformation.shared.getAppVersionName()
        
        FetchAPI.shared.fetchFormUrlencoded(path: "app/ReadLstAppVer.ajax", payload: payload, completion: completion)
    }
}
