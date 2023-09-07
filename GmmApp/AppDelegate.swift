//
//  AppDelegate.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //Thread.sleep(forTimeInterval: 0.5)
        debug("didFinishLaunchingWithOptions")
        
        // Firebase 설정
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        //Messaging.messaging().isAutoInitEnabled = true
        
        // UserNotifications 설정
        UNUserNotificationCenter.current().delegate = self
        GmmApplication.shared.initialize()
        application.registerForRemoteNotifications() // APN 서비스에 등록
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { data in String(format: "%02x", data) }.joined()
        log("apnsToken: \(token)")
        
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log("Failed to register: \(error)")
    }
    
    // Function that the app is called while background or not running
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo;
        debug("userInfo: \(userInfo)")
//        for (key, value) in userInfo {
//            debug("key: \(key), value: \(value)")
//        }
        //        debug("\(userInfo["gcm.message_id"] ?? "")")
        
        NotificationCenter.default.post(name: Notification.Name.pushNotification, object: nil, userInfo: userInfo)
        
        completionHandler()
    }
    
    // 앱이 실행되는 도중에 알림이 도착한 경우 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        debug("userInfo: \(notification.request.content.userInfo)")
        
        completionHandler([.banner, .sound, .badge])
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        log("fcmToken: \(fcmToken ?? "")")
        
        if let token = fcmToken {
            DeviceInformation.shared.setRegistrationToken(token)
        }
    }
}
