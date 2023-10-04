//
//  NotifictionService.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/20.
//

import Foundation
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    private var timer: Timer?
    
    private init() {
    }
    
    func fetchNewNtfcPtNcnt(completion: @escaping (Result<[String: Any], Error>) -> ()) {
        FetchAPI.shared.fetchFormUrlencoded(path: "ntfc/ReadNewNtfcPtNcnt.ajax", completion: completion)
    }
    
    func updateNtfcPtPrcgYn(_ pushNtfcPt: String) {
        guard UserInformation.shared.loginInfo != nil else {
            return
        }
        
        let ntfcPt = pushNtfcPt.components(separatedBy: "-")
        let payload = ["userId": ntfcPt[0], "ntfcDsptDtm": ntfcPt[1], "ntfcSno": ntfcPt[2]]

        FetchAPI.shared.fetchFormUrlencoded(path: "ntfc/UpdateNtfcPtPrcgYn.ajax", payload: payload) { result in
            if case .failure(let error) = result {
                log("error: \(String(describing: error))")
            }
        }
    }
    
    func startNotificationTimer() {
        if timer != nil {
            stopNotificationTimer()
        }
        
        //self.timer = Timer.scheduledTimer(timeInterval: 3 * 60.0, target: self, selector: #selector(updateNewNtfcPtNcnt), userInfo: nil, repeats: true)
        self.timer = Timer.scheduledTimer(withTimeInterval: 3 * 5.0, repeats: true) { timer in
            guard UserInformation.shared.loginInfo != nil else {
                return
            }
            
            self.fetchNewNtfcPtNcnt { result in
                NotificationCenter.default.post(name: Notification.Name.newNotification, object: nil, userInfo: ["result": result])
            }
        }
    }
    
    func stopNotificationTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension Notification.Name {
    static let pushNotification = Notification.Name("pushNotification")
    static let newNotification = Notification.Name("newNotification")
}
