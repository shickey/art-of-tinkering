//
//  Constants.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/11/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation

// Default URLs
let DOCUMENTS_FOLDER_URL  = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
let LOCAL_WEB_FOLDER_URL  = DOCUMENTS_FOLDER_URL.appendingPathComponent("web", isDirectory: true)
let PROJECTS_FOLDER_URL   = DOCUMENTS_FOLDER_URL.appendingPathComponent("projects", isDirectory: true)
let BUNDLE_WEB_FOLDER_URL = Bundle.main.url(forResource: "web", withExtension: nil)!
let PROJECTS_MANIFEST_URL = DOCUMENTS_FOLDER_URL.appendingPathComponent("aot.manifest")
let RELAY_SERVER_URL      = URL(string: "http://10.0.1.83:8080/")!

// UserDefaults
let USER_DEFAULTS_RELAY_SERVER_URL_KEY = "edu.mit.media.llk.ArtOfTinkering.relayServerUrl"
let USER_DEFAULTS_BACKGROUND_KEY = "edu.mit.media.llk.ArtOfTinkering.defaultBackground"
let DEFAULT_BACKGROUND_FILENAME = "739b5e2a2435f6e1ec2993791b423146.png" // White background
