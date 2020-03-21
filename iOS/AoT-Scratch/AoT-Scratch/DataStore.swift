//
//  DataStore.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/11/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import Foundation
import UIKit
import ZIPFoundation

struct Costume {
    let hash: String
    let image: UIImage
}

struct Project {
    weak var store: Store?
    var id: UUID
    var thumbnail: UIImage
    var json: String
    var costumes: [Costume]
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
    
    let lines = manifest.split(separator: "\n").map { String($0) }
    for line in lines {
        // @TODO: We're loading absolutely everything into memory for simplicity.
        //        We could (should?) lazy load some of this in the future
        //        if it makes sense to do so
        
        let split = line.split(separator: ",").map { String($0) }
        let projectId = split[0]
        let costumeHashes = split.dropFirst()
        
        let uuid = UUID(uuidString: projectId)!
        let projectFolderUrl = store.projectsFolderUrl.appendingPathComponent(projectId, isDirectory: true)
        let thumb = UIImage(contentsOfFile: projectFolderUrl.appendingPathComponent("thumb.png").path)!
        let json = try! String(contentsOf: projectFolderUrl.appendingPathComponent("sprite.json"))
        
        var costumes : [Costume] = []
        for hash in costumeHashes {
            let img = UIImage(contentsOfFile: projectFolderUrl.appendingPathComponent("\(hash).png").path)!
            let costume = Costume(hash: hash, image: img)
            costumes.append(costume)
        }
        
        let project = Project(store: store, id: uuid, thumbnail: thumb, json: json, costumes: costumes)
        store.projects.append(project)
    }
}

func saveProjectsManifest(store: Store, to url: URL) -> Bool {
    var manifest = ""
    for project in store.projects {
        manifest += "\(project.id.uuidString),\((project.costumes.map { $0.hash }).joined(separator: ","))\n"
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
    
    let thumbnail = resizeImageConstrained(to: 320, image: image)
    let projectId = UUID()
    let costume = createCostume(from: image)
    let costumes : [Costume] = [costume]
    let json = createSprite3Json(from: costumes)
    
    let project = Project(store: store, id: projectId, thumbnail: thumbnail, json: json, costumes: costumes)
    store.projects.append(project)
    
    writeProjectToDisk(project)
    saveProjectsManifest(store: store, to: PROJECTS_MANIFEST_URL)
    
    return project
}

func writeProjectToDisk(_ project: Project) {
    //@ TODO: Error Handling
    
    let projectFolderUrl = project.store!.projectsFolderUrl.appendingPathComponent("\(project.id.uuidString)")
    try! FileManager.default.createDirectory(at: projectFolderUrl, withIntermediateDirectories: true, attributes: nil)
    let thumbnailData = project.thumbnail.pngData()!
    try! thumbnailData.write(to: projectFolderUrl.appendingPathComponent("thumb.png"))
    for costume in project.costumes {
        try! costume.image.pngData()!.write(to: projectFolderUrl.appendingPathComponent("\(costume.hash).png"))
    }
    try! project.json.write(to: projectFolderUrl.appendingPathComponent("sprite.json"), atomically: true, encoding: .utf8)
}

func createCostume(from image: UIImage) -> Costume {
    let pngData = image.pngData()!
    let hash = md5(pngData)
    return Costume(hash: hash, image: image)
}

func createSprite3Json(from costumes: [Costume]) -> String {
    var costumesJson : [String] = []
    for costume in costumes {
        let costumeJson = """
            {
              "assetId": "\(costume.hash)",
              "name": "my-sprite",
              "bitmapResolution": 2,
              "md5ext": "\(costume.hash).png",
              "dataFormat": "png",
              "rotationCenterX": \(Int(costume.image.size.width) / 2),
              "rotationCenterY": \(Int(costume.image.size.height) / 2)
            }
        """
        costumesJson.append(costumeJson)
    }
    return """
        {
          "isStage": false,
          "name": "my-sprite",
          "variables": {},
          "lists": {},
          "broadcasts": {},
          "blocks": {},
          "comments": {},
          "currentCostume": 0,
          "costumes": [
            \(costumesJson.joined(separator: ","))
          ],
          "sounds": [],
          "volume": 100,
          "visible": true,
          "x": 0,
          "y": 0,
          "size": 100,
          "direction": 90,
          "draggable": false,
          "rotationStyle": "all around"
        }
    """
}

func createSprite3Archive(from project: Project) -> Data {
    let archive = Archive(accessMode: .create)!
    
    for costume in project.costumes {
        let pngData = costume.image.pngData()!
        try! archive.addEntry(with: "\(costume.hash).png", type: .file, uncompressedSize: UInt32(pngData.count)) { (position, size) -> Data in
            pngData.subdata(in: position..<position + size)
        }
    }
    
    
    let jsonData = project.json.data(using: .utf8)!
    try! archive.addEntry(with: "sprite.json", type: .file, uncompressedSize: UInt32(jsonData.count), provider: { (position, size) -> Data in
        jsonData.subdata(in: position..<position + size)
    })
    
    return archive.data!
}
