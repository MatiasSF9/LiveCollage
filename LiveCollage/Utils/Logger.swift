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
}

class Logger {
    
    static func log(type: LogType, string: String) {
        //TODO: disable if RELEASE
        self.log(string: type.rawValue + ": \(string)")
    }
    
    static func log(string: String) {
        print(string)
    }
    
}
