//
//  AppEnviroment.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation


enum BuildMode: String {
    case debug = "debug"
    case release = "release"
    
    static var current: BuildMode {
#if DEBUG // 조건부 컴파일 블록(Conditional Compilation Block)
        return debug
#else
        return release
#endif
    }
}

enum AppEnvironment {
    
    enum PlistKeys: String {
        case webRootURL = "WEB_ROOT_URL"
        case webMainPageURL = "WEB_MAIN_PAGE_URL"
    }
    
    private static var infoDictionary: [String: Any] { // type 연산 property
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        
        return dict
    }
    
    static let webRootUrl: URL = { // type 저장 property
        guard let webRootURLStr = AppEnvironment.infoDictionary[PlistKeys.webRootURL.rawValue] as? String else {
            fatalError("Web Root URL not set in plist for this environment")
        }
        guard let url = URL(string: webRootURLStr) else {
            fatalError("Web Root URL is invalid")
        }
        return url
//        if let url = URL(string: appURLStr) {
//            return url
//        } else {
//            fatalError("App URL is invalid")
//        }
    }()
    
    static let webMainPageURL: URL = {
        guard let webMainPageURLStr = AppEnvironment.infoDictionary[PlistKeys.webMainPageURL.rawValue] as? String else {
            fatalError("Web Main Page URL not set in plist for this environment")
        }
        guard let url = URL(string: webMainPageURLStr) else {
            fatalError("Web Main Page URL is invalid")
        }
        return url
    }()
}
