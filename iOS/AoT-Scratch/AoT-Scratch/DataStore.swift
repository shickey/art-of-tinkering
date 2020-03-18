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
    var id: UUID
    var thumbnail: UIImage
    var sprite3Data: Data
}

class Store {
    let projectsFolderUrl : URL
    var projects : [Project]
    
    init(projectsFolderUrl url: URL) {
        projectsFolderUrl = url
        projects = []
    }
}

let AotStore = Store(projectsFolderUrl: PROJECTS_FOLDER_URL)

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
        // @TODO: We're loading absolutely everything (thumbnails, sprite3 data) into
        //        memory just for simplicity. We could (should?) lazy load some of this
        //        in the future if it makes sense to do so
        
        let uuid = UUID(uuidString: projectId)!
        
        let projectFolderUrl = PROJECTS_FOLDER_URL.appendingPathComponent(projectId, isDirectory: true)
        let thumb = UIImage(contentsOfFile: projectFolderUrl.appendingPathComponent("thumb.png").path)!
        
        let sprite3 = try! Data(contentsOf: PROJECTS_FOLDER_URL.appendingPathComponent("project.sprite3"))
        
        let project = Project(id: uuid, thumbnail: thumb, sprite3Data: sprite3)  
        store.projects.append(project)
    }
}

func saveProjectsManifest(store: Store, to url: URL) -> Bool {
    var manifest = ""
    for project in store.projects {
        manifest += "\(project.id.uuidString)\n"
    }
    
    do {
        try manifest.write(to: url, atomically: true, encoding: .utf8)
        return true
    }
    catch {
        return false
    }
}

func createProjectWithImage(_ img: UIImage, in store: Store) -> Project {
    var image = img
    if image.size.width > 800 || image.size.height > 800 {
        image = resizeImageConstrained(to: 800, image: img)
    }
    
    let sprite3 = createSprite3Archive(from: image)
    let thumbnail = resizeImageConstrained(to: 320, image: image)
    let thumbnailData = thumbnail.pngData()!
    
    let projectId = UUID()
    let projectFolderUrl = PROJECTS_FOLDER_URL.appendingPathComponent("\(projectId.uuidString)")
    try! FileManager.default.createDirectory(at: projectFolderUrl, withIntermediateDirectories: true, attributes: nil)
    
    try! thumbnailData.write(to: projectFolderUrl.appendingPathComponent("thumb.png"))
    try! sprite3.write(to: projectFolderUrl.appendingPathComponent("project.sprite3"))
    
    let project = Project(id: projectId, thumbnail: thumbnail, sprite3Data: sprite3)
    store.projects.append(project)
    return project
}
