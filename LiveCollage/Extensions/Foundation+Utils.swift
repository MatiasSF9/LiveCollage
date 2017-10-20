//
//  Foundation+Utils.swift
//  LiveCollage
//
//  Created by Matias Fernandez on 18/10/2017.
//  Copyright © 2017 M2Media. All rights reserved.
//

import Foundation

//MARK: Utility Methods
extension URL {
    func CFURL() -> CFURL? {
        let ns = self as NSURL
        return ns as CFURL
    }
}

extension Dictionary {
    func CFDictionary() -> CFDictionary? {
        return NSDictionary(dictionary: self) as CFDictionary
    }
}

extension Data {
    func CFData() -> CFData? {
        let data = NSData(data: self) as CFData
        return data
    }
}

