//
//  File.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 8/20/17.
//  Copyright © 2017 M2Media. All rights reserved.
//

import Foundation

enum LogType: String {
    case VERBOSE = "🔤VERBOSE"
    case DEBUG = "🔎DEBUG"
    case WARNING = "⚠️WARNING"
    case ERROR = "❗️❗️❗️ERROR"
}

class Logger {
    
    static func VERBOSE(message: String) {
        log(type: .VERBOSE, string: message)
    }
    
    static func DEBUG(message: String) {
        log(type: .DEBUG, string: message)
    }
    
    static func WARNING(message: String) {
        log(type: .WARNING, string: message)
    }
    
    static func ERROR(message: String) {
        log(type: .ERROR, string: message)
    }
    
    static func log(type: LogType, string: String) {
        //TODO: disable if RELEASE
        log(string: type.rawValue + ": \(string)")
    }
    
    static func log(string: String) {
        print(string)
    }
    
}
