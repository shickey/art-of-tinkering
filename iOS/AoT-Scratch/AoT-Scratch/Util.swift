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

@inline(__always)
func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
    let yDiffSquared = ((point2.y - point1.y) * (point2.y - point1.y))
    let xDiffSquared = ((point2.x - point1.x) * (point2.x - point1.x))
    return sqrt(yDiffSquared + xDiffSquared)
}

@inline(__always)
func perpendicularDistance(_ point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
    let numerator = ((lineEnd.y - lineStart.y) * point.x) - ((lineEnd.x - lineStart.x) * point.y) + (lineEnd.x * lineStart.y) - (lineEnd.y * lineStart.x)
    return abs(numerator) / distance(lineStart, lineEnd)
}

func ramerDouglasPeucker(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
    if points.count < 3 { return points }
    
    // Find the point farthest from the line between the starting and ending points
    var maxDistance : CGFloat = 0.0
    var maxDistIdx = 1 // Start from the second point in the array
    let firstPoint = points.first!
    let lastPoint = points.last!
    for i in 1..<(points.count - 1) {
        let point = points[i]
        let distance = perpendicularDistance(point, lineStart: firstPoint, lineEnd: lastPoint)
        if distance > maxDistance {
            maxDistance = distance
            maxDistIdx = i
        }
    }
    
    if maxDistance < tolerance {
        return [firstPoint, lastPoint]
    }
    
    let leftRecurse = ramerDouglasPeucker(Array(points[0...maxDistIdx]), tolerance: tolerance)
    let rightRecurse = ramerDouglasPeucker(Array(points[maxDistIdx..<points.count]), tolerance: tolerance)
    
    return leftRecurse + rightRecurse[1..<rightRecurse.count]
}
