//
//  Constants.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/11/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation

let DOCUMENTS_FOLDER_URL     = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
let LOCAL_WEB_FOLDER_URL     = DOCUMENTS_FOLDER_URL.appendingPathComponent("web", isDirectory: true)
let SPRITE_IMAGES_FOLDER_URL = DOCUMENTS_FOLDER_URL.appendingPathComponent("sprite-images", isDirectory: true)
let BUNDLE_WEB_FOLDER_URL    = Bundle.main.url(forResource: "web", withExtension: nil)!
