//
//  NotificationService.swift
//  GmmAppNotificationService
//
//  Created by GwangHyeok Yu on 2023/09/01.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            debug("\(bestAttemptContent)")
            // Modify the notification content here...
            //            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            
            if let fcmOptionsUserInfo = bestAttemptContent.userInfo["fcm_options"] as? [String: Any] {
                guard var imageURLString = fcmOptionsUserInfo["image"] as? String else {
                    contentHandler(bestAttemptContent)
                    return
                }
                if !imageURLString.hasPrefix("http") {
                    imageURLString = "https://bfcs.tmoney.co.kr" + imageURLString
                }
                var imgSuffix = ".png"
                if let _ = imageURLString.range(of: "(.jpg|.jpeg)$", options: .regularExpression) {
                //if imageURLString.hasSuffix(".jpg") {
                    imgSuffix = ".jpg"
                }
                let imageURL = URL(string: imageURLString)!
                
                // download image
                guard let imageData = try? Data(contentsOf: imageURL) else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                // set UNNotificationAttachment
                guard let attachment = UNNotificationAttachment.saveImageToDisk(identifier: (bestAttemptContent.userInfo["gcm.message_id"] as? String ?? "gmmPushImg") + imgSuffix, data: imageData, options: nil) else {
                    contentHandler(bestAttemptContent)
                    return
                }
                bestAttemptContent.attachments = [attachment]
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

extension UNNotificationAttachment {
    static func saveImageToDisk(identifier: String, data: Data, options: [AnyHashable : Any]? = nil) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)!
        
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            let fileURL = folderURL.appendingPathExtension(identifier)
            try data.write(to: fileURL)
            let attachment = try UNNotificationAttachment(identifier: identifier, url: fileURL, options: options)
            return attachment
        } catch {
            print("saveImageToDisk error - \(error)")
        }
        return nil
    }
}
