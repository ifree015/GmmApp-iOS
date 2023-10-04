//
//  FetchAPI.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/18.
//

import Foundation

struct FetchAPI {
    
    static var shared = FetchAPI()
    
    private init() {
    }
    
    func fetchFormUrlencoded(path: String, payload: [String: String]? = nil, headers: [String: String] = [:], timeout: TimeInterval = 10.0, completion: @escaping (Result<Dictionary<String, Any>, Error>) -> ()) {
        let urlString = AppEnvironment.apiURL.absoluteString + path
        //debug(urlString)
        guard let url = URL(string: urlString) else {
            completion(.failure(FetchError.urlInvalid("URL(\(urlString)) is invalid.")))
            return
        }
        
        var requestHeaders = headers
        requestHeaders["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
        
        var requestBody = URLComponents()
        requestBody.queryItems = payload?.map {(key, value) in
            //URLQueryItem(name: $0.key, value: $0.value)
            URLQueryItem(name: key, value: value)
        }
        
        fetchPost(url, payload: requestBody.query?.data(using: .utf8), headers: requestHeaders, timeout: timeout, completion: completion)
    }
    
    func fetchPost(_ url: URL, payload: Data?, headers: [String: String], timeout: TimeInterval, completion: @escaping (Result<[String: Any], Error>) -> ()) {
        var request: URLRequest = URLRequest(url: url)
        if timeout > 0 {
            request.timeoutInterval = timeout
        }
        request.httpMethod = "POST"
        headers.forEach {(key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = payload
        
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request) {
            (data, response, error) in
            guard error == nil else {
                log("error: \(String(describing: error))")
                completion(.failure(FetchError.sysError(code: MessageCode.C5001.code, message: MessageCode.C5001.message)))
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                completion(.failure(FetchError.sysError(code: MessageCode.C5002.code, message: MessageCode.C5002.message)))
                return
            }
            
            let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            
            if (200..<300) ~= response.statusCode {
                guard let jsonObj = jsonObj else {
                    completion(.failure(FetchError.sysError(code: MessageCode.C5003.code, message: MessageCode.C5003.message)))
                    return
                }
                if let result = jsonObj["result"] as? String, result == "error", let bizError = jsonObj["error"] as? [String: String] {
                    completion(.failure(FetchError.bizError(code: bizError["code"] ?? "", message: bizError["message"] ?? "", response: jsonObj)))
                    return
                }
                
                completion(.success(jsonObj))
            } else {
                log("statusCode: \(response.statusCode)")
                if let jsonObj = jsonObj, let bizError = jsonObj["error"] as? [String: String] {
                    completion(.failure(FetchError.bizError(code: bizError["code"] ?? "", message: bizError["message"] ?? "", response: jsonObj)))
                    return
                }
                completion(.failure(FetchError.sysError(code: MessageCode.C5002.code, message: MessageCode.C5002.message)))
            }
        }
        
        dataTask.resume()
    }
    
    func fetchFormUrlencoded(path: String, payload: [String: String]? = nil, headers: [String: String] = [:]) async throws -> [String: Any] {
        let urlString = AppEnvironment.apiURL.absoluteString + path
        guard let url = URL(string: urlString) else {
            throw FetchError.urlInvalid("URL(\(urlString)) is invalid.")
        }
        
        var requestHeaders = headers
        requestHeaders["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
        
        var requestBody = URLComponents()
        requestBody.queryItems = payload?.map {(key, value) in
            //URLQueryItem(name: $0.key, value: $0.value)
            URLQueryItem(name: key, value: value)
        }
        
        return try await fetchPost(url, payload: requestBody.query?.data(using: .utf8), headers: requestHeaders)
    }
    
    func fetchPost(_ url: URL, payload: Data?, headers: [String: String]) async throws -> [String: Any] {
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach {(key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = payload
        
        let session = URLSession(configuration: .default)
        let res: (data: Data?, response: URLResponse?)
        do {
            res = try await session.data(for: request)
        } catch {
            debug("error: \(String(describing: error))")
            throw FetchError.sysError(code: MessageCode.C5001.code, message: MessageCode.C5001.message)
        }
        
        guard let data = res.data, let response = res.response as? HTTPURLResponse else {
            throw FetchError.sysError(code: MessageCode.C5002.code, message: MessageCode.C5002.message)
        }
        
        let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
        if (200..<300) ~= response.statusCode {
            guard let jsonObj = jsonObj else {
                throw FetchError.sysError(code: MessageCode.C5003.code, message: MessageCode.C5003.message)
            }
            if let result = jsonObj["result"] as? String, result == "error", let bizError = jsonObj["error"] as? [String: String] {
                throw FetchError.bizError(code: bizError["code"] ?? "", message: bizError["message"] ?? "", response: jsonObj)
            }
            
            return jsonObj
        } else {
            if let jsonObj = jsonObj, let bizError = jsonObj["error"] as? [String: String] {
                throw FetchError.bizError(code: bizError["code"] ?? "", message: bizError["message"] ?? "", response: jsonObj)
            }
            
            throw FetchError.sysError(code: MessageCode.C5002.code, message: MessageCode.C5002.message)
        }
    }
}

enum FetchError: Error {
    case urlInvalid(_ message: String)
    case sysError(code: String, message: String)
    case bizError(code: String, message: String, response: Any)
}

struct MessageCode {
    let code: String
    let message: String
    
    static let C5001 = MessageCode(code: "C5001", message: "API 서버 접속에 실패했습니다.")
    static let C5002 = MessageCode(code: "C5002", message: "API 호출에 실패했습니다.")
    static let C5003 = MessageCode(code: "C5003", message: "JSON 객체 변환에 실패했습니다.")
    
    private init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}
