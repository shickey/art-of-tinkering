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
        // Override point for customization after application launch.
        
        let fm = FileManager.default
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let localWebFolderUrl = documents.appendingPathComponent("web", isDirectory: true)
        let spriteImagesUrl = documents.appendingPathComponent("sprite-images", isDirectory: true)
        if !fm.fileExists(atPath: spriteImagesUrl.path) {
            try! FileManager.default.createDirectory(at: spriteImagesUrl, withIntermediateDirectories: true, attributes: nil)
        }
        
        let symLinkedAssetsUrl = localWebFolderUrl.appendingPathComponent("sprite-images")
        
        let bundleWebFolderUrl = Bundle.main.url(forResource: "web", withExtension: nil)!
        
        if fm.fileExists(atPath: localWebFolderUrl.path) {
            try! fm.removeItem(at: localWebFolderUrl)
        }
        try! FileManager.default.copyItem(at: bundleWebFolderUrl, to: localWebFolderUrl)
        
        if !fm.fileExists(atPath: symLinkedAssetsUrl.path) {
            try! FileManager.default.createSymbolicLink(at: symLinkedAssetsUrl, withDestinationURL: spriteImagesUrl)
        }
        
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

