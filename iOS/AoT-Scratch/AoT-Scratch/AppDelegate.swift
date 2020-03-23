//
//  AppDelegate.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 2/28/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create the folder where we'll save images created with the app
        let fm = FileManager.default
        if !fm.fileExists(atPath: PROJECTS_FOLDER_URL.path) {
            try! FileManager.default.createDirectory(at: PROJECTS_FOLDER_URL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Copy the Scratch GUI web resources to a local folder (so that both it, and the sprite images folder can be accessed by WKWebView)
        if fm.fileExists(atPath: LOCAL_WEB_FOLDER_URL.path) {
            try! fm.removeItem(at: LOCAL_WEB_FOLDER_URL)
        }
        try! FileManager.default.copyItem(at: BUNDLE_WEB_FOLDER_URL, to: LOCAL_WEB_FOLDER_URL)
        
        // Initialize user defaults (if necessary)
        let userDefaults = UserDefaults.standard
        if userDefaults.url(forKey: USER_DEFAULTS_RELAY_SERVER_URL_KEY) == nil {
            userDefaults.set(RELAY_SERVER_URL, forKey: USER_DEFAULTS_RELAY_SERVER_URL_KEY)
        }
        if userDefaults.string(forKey: USER_DEFAULTS_BACKGROUND_KEY) == nil {
            userDefaults.set(DEFAULT_BACKGROUND_FILENAME, forKey: USER_DEFAULTS_BACKGROUND_KEY)
        }
        
        // Initialize data store
        loadProjectsFromManifest(manifestUrl: PROJECTS_MANIFEST_URL, into: AotStore)
        
        return true
    }

}

