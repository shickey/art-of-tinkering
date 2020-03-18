//
//  Logging.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/18/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation

func debugLog(_ message: String) {
    #if DEBUG
    print("[AoT]: \(message)")
    #endif
}


