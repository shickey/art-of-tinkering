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
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

