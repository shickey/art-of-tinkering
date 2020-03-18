//
//  SpriteGenerator.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/17/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import ZIPFoundation

func createSprite3Archive(from image: UIImage) -> Data {
    let archive = Archive(accessMode: .create)!
    
    let pngData = image.pngData()!
    let imageHash = md5(pngData)
    try! archive.addEntry(with: "\(imageHash).png", type: .file, uncompressedSize: UInt32(pngData.count)) { (position, size) -> Data in
        pngData.subdata(in: position..<position + size)
    }
    
    let jsonData = generateSprite3Json(imageHash: imageHash, imageSize: image.size).data(using: .utf8)!
    try! archive.addEntry(with: "sprite.json", type: .file, uncompressedSize: UInt32(jsonData.count), provider: { (position, size) -> Data in
        jsonData.subdata(in: position..<position + size)
    })
    
    return archive.data!
}

func generateSprite3Json(imageHash: String, imageSize: CGSize) -> String {
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
            {
              "assetId": "\(imageHash)",
              "name": "my-sprite",
              "bitmapResolution": 2,
              "md5ext": "\(imageHash).png",
              "dataFormat": "png",
              "rotationCenterX": \(Int(imageSize.width) / 2),
              "rotationCenterY": \(Int(imageSize.height) / 2)
            }
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
