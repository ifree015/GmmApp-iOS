//
//  LogUtils.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/04/27.
//

import Foundation


func debug<T>(_ object: T?, filename: String = #file, _ line: Int = #line, _ funcName: String = #function) {
#if DEBUG
    if let obj = object {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(abbreviation: "KST")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        //debugPrint("\(dateFormatter.string(from: Date())) [\((filename as NSString).lastPathComponent), in \(funcName) at line: \(line)]: \(obj)")
        debugPrint("\(dateFormatter.string(from: Date())) [\((filename as NSString).lastPathComponent)(\(line)) \(funcName)] \(obj)")
    }
#endif
}

func log<T>(_ object: T?, filename: String = #file, _ line: Int = #line, _ funcName: String = #function) {
    if let obj = object {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        //print("\(dateFormatter.string(from: Date())) [\((filename as NSString).lastPathComponent), in \(funcName) at line: \(line)]: \(obj)")
        print("\(dateFormatter.string(from: Date())) [\((filename as NSString).lastPathComponent)(\(line)) \(funcName)] \(obj)")
    }
}

