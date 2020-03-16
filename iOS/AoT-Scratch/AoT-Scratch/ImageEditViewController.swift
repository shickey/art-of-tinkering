//
//  ImageEditViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/6/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import simd

class ColorView : UIView {
    
    var color: UIColor = UIColor.red
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
    }
}

struct PixelValue {
    var r : Int
    var g : Int
    var b : Int
}

class ImageSampler {
    var image : UIImage! = nil
    var imageContext : CGContext! = nil
    var imageDataPtr : UnsafeMutableRawPointer! = UnsafeMutableRawPointer(bitPattern: 0)
    
    init(image newImage: UIImage) {
        image = newImage
        
        let cgImage = image.cgImage!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        imageContext = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
        imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        imageDataPtr = imageContext.data!
    }
    
    func imagePixelValue(at point: CGPoint) -> PixelValue {
        let cgImage = image.cgImage!
        let x = Int(point.x)
        let y = Int(point.y)
        let offset = (4 * cgImage.width * y) + (4 * x)
        let pixelPtr = imageDataPtr + offset
        let bytes = pixelPtr.bindMemory(to: UInt8.self, capacity: 4)
        return PixelValue(r: Int(bytes[0]), g: Int(bytes[1]), b: Int(bytes[2]))
    }
}

class ThresholdGestureRecognizer : UIGestureRecognizer {
    
    var trackedTouch : UITouch? = nil
    var start : CGPoint? = nil
    var end : CGPoint? = nil
    
    var distance : CGFloat {
        if let p1 = start, let p2 = end {
            return CGFloat(hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y)));
        }
        return 0.0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if trackedTouch == nil {
            if let firstTouch = touches.first {
                trackedTouch = firstTouch
                start = trackedTouch!.location(in: view)
                state = .began
            }
        }
        else {
            for touch in touches {
               if touch != trackedTouch {
                  ignore(touch, for: event)
               }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        end = touches.first!.location(in: view)
        state = .changed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        end = touches.first!.location(in: view)
        state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        trackedTouch = nil
        start = nil
        end = nil
        state = .cancelled
    }
    
    override func reset() {
        trackedTouch = nil
        start = nil
        end = nil
    }
    
}

class ImageEditViewController: UIViewController {
    
    var projectManager : ProjectManager! = nil
    var image : UIImage! = nil
    var filter = ChromaKeyFilter()
    var sampler : ImageSampler! = nil
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var colorView: ColorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if nil != image {
            imageView.image = image
            sampler = ImageSampler(image: image)
            filter.input = CIImage(image: image)!
            filter.chromaColor = SIMD3<Float>(0, 1.0, 0)
        }
    }

    @IBAction func thresholdGestureRecognized(_ sender: ThresholdGestureRecognizer) {
        switch sender.state {
        case .began:
            print("began")
            let pt = sender.start!
            let ivWidth = imageView.bounds.width
            let ivHeight = imageView.bounds.height
            let ivAspect = ivWidth / ivHeight
            let imageAspect = image.size.width / image.size.height
            var convertedPt = CGPoint(x: 0, y: 0)
            if ivAspect > imageAspect {
                // Height constrained
                let scale = image.size.height / ivHeight
                let xOffset = (ivWidth - (image.size.width / scale)) / 2.0
                let x = (pt.x - xOffset) * scale
                let y = (pt.y * scale)
                convertedPt = CGPoint(x: x, y: y)
            }
            else {
                // Width constrained
                let scale = image.size.width / ivWidth
                let yOffset = (ivHeight - (image.size.height / scale)) / 2.0
                let x = pt.x  * scale
                let y = (pt.y - yOffset) * scale
                convertedPt = CGPoint(x: x, y: y)
            }
            let pixelColor = sampler.imagePixelValue(at: convertedPt)
            let pickedColor = UIColor(red: CGFloat(pixelColor.r) / 255.0, green: CGFloat(pixelColor.g) / 255.0, blue: CGFloat(pixelColor.b) / 255.0, alpha: 1.0)
            colorView.color = pickedColor
            colorView.setNeedsDisplay()
            filter.chromaColor = SIMD3<Float>(Float(pixelColor.r) / 255.0, Float(pixelColor.g) / 255.0, Float(pixelColor.b) / 255.0)
            filter.threshold = 0.0
            imageView.image = UIImage(ciImage: filter.outputImage!)
            
        case .changed:
            let dist = sender.distance
            let width = imageView.bounds.width
            filter.threshold = clamp(Float(dist / (width / 2.0)), 0, 1.0)
            imageView.image = UIImage(ciImage: filter.outputImage!)
        case .ended: break
        default: break
        }
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        let bigImg = UIImage(ciImage: filter.outputImage!)
        
        // Resize the image to max 800px in the larger dimension
        var size = CGSize.zero
        if bigImg.size.width > bigImg.size.height {
            // Landscape
            // It should already be in 4:3 but just in case...
            let ratio = 800.0 / bigImg.size.width
            let newHeight = bigImg.size.height * ratio
            size = CGSize(width: 800.0, height: newHeight)
        }
        else {
            // Portrait
            let ratio = 800.0 / bigImg.size.height
            let newWidth = bigImg.size.width * ratio
            size = CGSize(width: newWidth, height: 800.0)
        }
        
        UIGraphicsBeginImageContext(size)
        bigImg.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let png = img.pngData()!
        let hash = md5(png)
        
        let fileUrl = SPRITE_IMAGES_FOLDER_URL.appendingPathComponent("\(hash).png")
        try! png.write(to: fileUrl)
        
        let project = Project(id: hash, image: img)
        
        projectManager.projectWasCreated(project: project)
    }
    
}
