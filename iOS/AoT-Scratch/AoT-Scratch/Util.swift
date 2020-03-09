//
//  Util.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/7/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation
import CommonCrypto

func md5(_ data: Data) -> String {
    let length = CC_LONG(data.count)
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    let _ = data.withUnsafeBytes { (ptr) in
        CC_MD5(ptr, length, &digest)
    }
    
    return digest.map { String(format: "%02hhx", $0) }.joined()
}

@inline(__always)
func clamp<T>(_ val: T, _ min: T, _ max: T) -> T where T:Numeric, T:Comparable {
    if val < min { return min }
    if val > max { return max }
    return val
} 
