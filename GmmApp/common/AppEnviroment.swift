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
        case loginPageURL = "LOGIN_PAGE_URL"
        case mainPageURL = "MAIN_PAGE_URL"
        case apiDomain = "API_DOMAIN"
        case apiURL = "API_URL"
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
    
    static let loginPageUrl: URL = {
        guard let loginPageURLStr = AppEnvironment.infoDictionary[PlistKeys.loginPageURL.rawValue] as? String else {
            fatalError("Login Page URL not set in plist for this environment")
        }
        guard let url = URL(string: loginPageURLStr) else {
            fatalError("Login Page URL is invalid")
        }
        return url
    }()
    
    static let mainPageURL: URL = {
        guard let mainPageURLStr = AppEnvironment.infoDictionary[PlistKeys.mainPageURL.rawValue] as? String else {
            fatalError("Main Page URL not set in plist for this environment")
        }
        guard let url = URL(string: mainPageURLStr) else {
            fatalError("Main Page URL is invalid")
        }
        return url
    }()
    
    static let centPageURL: URL = {
        return  URL(string: mainPageURL.absoluteString + "centtrcndsbl")!
    }()
    
    static let trcnPageURL: URL = {
        return URL(string: mainPageURL.absoluteString + "trcndsbl")!
    }()
    
    static let apiDomain: String = {
        guard let apiDomain = AppEnvironment.infoDictionary[PlistKeys.apiDomain.rawValue] as? String else {
            fatalError("API Domain not set in plist for this environment")
        }
        return apiDomain
    }()
    
    static let apiURL: URL = {
        guard let apiURLStr = AppEnvironment.infoDictionary[PlistKeys.apiURL.rawValue] as? String else {
            fatalError("API URL not set in plist for this environment")
        }
        guard let url = URL(string: apiURLStr) else {
            fatalError("API URL is invalid")
        }
        return url
    }()
}
