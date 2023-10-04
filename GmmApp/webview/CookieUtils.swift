//
//  CookieUtils.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/18.
//

import Foundation
import WebKit

struct CookieUtils {
    
    ///  인증  tokens 설정
    static func setAuthTokens(completion: (() -> Void)? = nil) {
        //        guard let loginInfo = UserInformation.shared.loginInfo else {
        //            return
        //        }
        //        guard let accessTokenCookie = HTTPCookie(properties: [
        //            .domain: "",
        //            .path: "/",
        //            .name: "accessToken",
        //            .value: loginInfo.accessToken,
        //            .secure: (BuildMode.current == .debug) ? "FALSE" : "TRUE"
        ////            .expires: NSDate(timeIntervalSinceNow: TimeInterval(loginInfo.appTimeout * 60)
        //            ]) else { return }
        guard let refreshTokenCookie = HTTPCookie(properties: [
            .domain: AppEnvironment.apiURL,
            .path: "/",
            .name: "refreshToken",
            .value: UserInformation.shared.getRefreshToken() ?? "",
            .secure: (BuildMode.current == .debug) ? "FALSE" : "TRUE"
            ]) else { return }
        let cookies = [refreshTokenCookie]

        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        for cookie: HTTPCookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        
        completion?()
    }
    
    /// HTTPCookieStorage.shared의 쿠키들을 WKWebView에 동기화
    static func syncToWebView(webView: WKWebView, completion: (() -> Void)?) {
        if var cookies = HTTPCookieStorage.shared.cookies {
            cookies = cookies.filter {["accessToken", "refreshToken"].contains($0.name) && ($0.domain == AppEnvironment.apiDomain)}
            let group = DispatchGroup()
            cookies.forEach({ cookie in
                group.enter()
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            })
            group.notify(queue: .main) {
                completion?()
            }
        }
    }
    
    /// WKWebView의 쿠키들을 HTTPCookieStorage.shared에 동기화
    static func syncToURLSession(webView: WKWebView, completion: (() -> Void)? = nil) {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies {(cookies: [HTTPCookie]) -> Void in
            let authCookies = cookies.filter {["accessToken", "refreshToken"].contains($0.name) && ($0.domain == AppEnvironment.apiDomain)}
            for cookie: HTTPCookie in authCookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            completion?()
        }
    }
}
