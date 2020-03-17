//
//  DataStore.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/11/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation
import UIKit

struct Project {
    var id: String // md5 hash of the asset
    var image: UIImage
}

class Store {
    let assetsUrl : URL
    var projects : [Project]
    
    init(assetsUrl url: URL) {
        assetsUrl = url
        projects = []
    }
}

let AotStore = Store(assetsUrl: SPRITE_IMAGES_FOLDER_URL)

func loadProjectsFromManifest(manifestUrl: URL, into store: Store, overwriteProjects : Bool = true) {
    var manifest : String = ""
    do {
        try manifest = String(contentsOf: manifestUrl) 
    }
    catch {
        // If we can't load the file, create an empty one
        try! "".write(to: manifestUrl, atomically: true, encoding: .utf8)
    }
    
    if overwriteProjects {
        store.projects = []
    }
    
    let lines = manifest.split(separator: "\n").map { String($0) };
    for projectId in lines {
        let projectImage = loadPngImageAsset(projectId, assetFolderUrl: SPRITE_IMAGES_FOLDER_URL)
        if projectImage == nil {
            print("WARNING: Failed to load image for project \(projectId). Skipping project.")
            continue
        }
        let project = Project(id: String(projectId), image: projectImage!)    
        store.projects.append(project)
    }
}

func saveProjectsManifest(store: Store, to url: URL) -> Bool {
    var manifest = ""
    for project in store.projects {
        manifest += "\(project.id)\n"
    }
    
    do {
        try manifest.write(to: url, atomically: true, encoding: .utf8)
        return true
    }
    catch {
        return false
    }
}

func loadPngImageAsset(_ md5Hash: String, assetFolderUrl: URL) -> UIImage? {
    let assetUrl = assetFolderUrl.appendingPathComponent("\(md5Hash).png")
    return UIImage(contentsOfFile: assetUrl.path)
}

func createProjectWithImage(_ img: UIImage, in store: Store) -> Project {
    // Resize the image to max 800px in the larger dimension
    var size = CGSize.zero
    if img.size.width > img.size.height {
        // Landscape
        // It should already be in 4:3 but just in case...
        let ratio = 800.0 / img.size.width
        let newHeight = img.size.height * ratio
        size = CGSize(width: 800.0, height: newHeight)
    }
    else {
        // Portrait
        let ratio = 800.0 / img.size.height
        let newWidth = img.size.width * ratio
        size = CGSize(width: newWidth, height: 800.0)
    }
    
    UIGraphicsBeginImageContext(size)
    img.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let storeImg = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    let png = storeImg.pngData()!
    let hash = md5(png)
    
    let fileUrl = SPRITE_IMAGES_FOLDER_URL.appendingPathComponent("\(hash).png")
    try! png.write(to: fileUrl)
    
    let project = Project(id: hash, image: storeImg)
    store.projects.append(project)
    return project
}
