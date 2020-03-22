//
//  Util.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/7/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
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

func resizeImageConstrained(to largestDimension: CGFloat, image: UIImage) -> UIImage {
    var size = CGSize.zero
    if image.size.width > image.size.height {
        // Landscape
        let ratio = largestDimension / image.size.width
        let newHeight = image.size.height * ratio
        size = CGSize(width: largestDimension, height: newHeight)
    }
    else {
        // Portrait
        let ratio = largestDimension / image.size.height
        let newWidth = image.size.width * ratio
        size = CGSize(width: newWidth, height: largestDimension)
    }
    
    UIGraphicsBeginImageContext(size)
    image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let resizedImg = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return resizedImg
}

extension UIColor {
    convenience init(hex: UInt) {
        let r = CGFloat((hex & 0x00FF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x0000FF00) >> 8) / 255.0
        let b = CGFloat((hex & 0x000000FF)) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension URL {
    func withoutScheme() -> String {
        if let scheme = self.scheme {
            let schemeWithSlashes = "\(scheme)://"
            return self.absoluteString.replacingOccurrences(of: schemeWithSlashes, with: "")
        }
        return self.absoluteString
    }
}
