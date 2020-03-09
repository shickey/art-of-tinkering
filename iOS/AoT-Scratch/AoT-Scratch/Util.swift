//
//  Util.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/7/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation

@inline(__always)
func clamp<T>(_ val: T, _ min: T, _ max: T) -> T where T:Numeric, T:Comparable {
    if val < min { return min }
    if val > max { return max }
    return val
} 
