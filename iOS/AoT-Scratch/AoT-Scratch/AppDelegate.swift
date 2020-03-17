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
        if !fm.fileExists(atPath: SPRITE_IMAGES_FOLDER_URL.path) {
            try! FileManager.default.createDirectory(at: SPRITE_IMAGES_FOLDER_URL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Copy the Scratch GUI web resources to a local folder (so that both it, and the sprite images folder can be accessed by WKWebView)
        if fm.fileExists(atPath: LOCAL_WEB_FOLDER_URL.path) {
            try! fm.removeItem(at: LOCAL_WEB_FOLDER_URL)
        }
        try! FileManager.default.copyItem(at: BUNDLE_WEB_FOLDER_URL, to: LOCAL_WEB_FOLDER_URL)
        
        // Initialize data store
        loadProjectsFromManifest(manifestUrl: PROJECTS_MANIFEST_URL, into: AotStore)
        
        return true
    }

}

