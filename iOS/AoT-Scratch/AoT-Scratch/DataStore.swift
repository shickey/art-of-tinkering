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

func loadProjectsManifest(_ url: URL) -> [Project] {
    var manifest : String = ""
    do {
        try manifest = String(contentsOf: url) 
    }
    catch {
        // If we can't load the file, create an empty one
        try! "".write(to: url, atomically: true, encoding: .utf8)
    }
    
    var projects : [Project] = []
    let lines = manifest.split(separator: "\n").map { String($0) };
    for projectId in lines {
        let projectImage = loadPngImageAsset(projectId, assetFolderUrl: SPRITE_IMAGES_FOLDER_URL)
        if projectImage == nil {
            print("WARNING: Failed to load image for project \(projectId). Skipping project.")
            continue
        }
        let project = Project(id: String(projectId), image: projectImage!)
        
        projects.append(project)
    }
    return projects
}

func saveProjectsManifest(to url: URL, for projects: [Project]) -> Bool {
    var manifest = ""
    for project in projects {
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
