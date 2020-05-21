//
//  ImageEditorViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 3/6/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import simd
import AVFoundation

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

class RegionGrower {
    var image : UIImage! = nil
    var imageSize : CGSize! = nil
    var imageContext : CGContext! = nil
    var imageDataPtr : UnsafeMutableRawPointer! = UnsafeMutableRawPointer(bitPattern: 0)
    var regionDataPtr : UnsafeMutableRawPointer! = nil
    
    init(image newImage: UIImage) {
        image = newImage
        
        let cgImage = image.cgImage!
        imageSize = image.size
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        imageContext = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
        imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        imageDataPtr = imageContext.data!
        
        regionDataPtr = malloc(cgImage.width * cgImage.height) // grayscale
    }
    
    func imagePixelValue(at point: CGPoint) -> PixelValue {
        let x = Int(point.x)
        let y = Int(point.y)
        let offset = (4 * Int(imageSize.width) * y) + (4 * x)
        let pixelPtr = imageDataPtr + offset
        let bytes = pixelPtr.bindMemory(to: UInt8.self, capacity: 4)
        return PixelValue(r: Int(bytes[0]), g: Int(bytes[1]), b: Int(bytes[2]))
    }
    
    func search(seed: CGPoint, threshold: Float) {
        memset(regionDataPtr, Int32(0), Int(imageSize.width * imageSize.height))
        let regionBuffer = regionDataPtr.bindMemory(to: UInt8.self, capacity: Int(imageSize.width * imageSize.height))
        
        let seedPixel = imagePixelValue(at: seed)
        
        var searchQueue = [seed]
        var searchIdx = 0
        while (searchIdx < searchQueue.count) {
            let current = searchQueue[searchIdx]
            searchIdx += 1
            // It's possible this pixel was added my multiple previous checks, so we may have already checked it
            // If so, bail early
            let currentOffset = (Int(current.y) * Int(image.size.width)) + Int(current.x)
            if regionBuffer[currentOffset] != 0 {
                continue
            }
            
            let currentPixel = imagePixelValue(at: current)
            let distance = dist(currentPixel, seedPixel)
            if distance <= threshold {
                // Set the current pixel to *in* the region
                regionBuffer[currentOffset] = 0xFF
                
                // Add adjacent pixels to the search queue if they haven't been checked yet
                let leftIdx = currentOffset - 1
                let rightIdx = currentOffset + 1
                let upIdx = currentOffset - Int(imageSize.width)
                let downIdx = currentOffset + Int(imageSize.width)
                if (leftIdx >= 0 && regionBuffer[leftIdx] == 0) {
                    let pt = CGPoint(x: leftIdx % Int(imageSize.width), y: leftIdx / Int(imageSize.width))
                    searchQueue.append(pt)
                }
                if (rightIdx < Int(imageSize.width * image.size.height) && regionBuffer[rightIdx] == 0) {
                    let pt = CGPoint(x: rightIdx % Int(imageSize.width), y: rightIdx / Int(imageSize.width))
                    searchQueue.append(pt)
                }
                if (upIdx >= 0 && regionBuffer[upIdx] == 0) {
                    let pt = CGPoint(x: upIdx % Int(imageSize.width), y: upIdx / Int(imageSize.width))
                    searchQueue.append(pt)
                }
                if (downIdx < Int(imageSize.width * image.size.height) && regionBuffer[downIdx] == 0) {
                    let pt = CGPoint(x: downIdx % Int(imageSize.width), y: downIdx / Int(imageSize.width))
                    searchQueue.append(pt)
                }
            }
            else {
                // Set the pixel to *out* of the region
                regionBuffer[currentOffset] = 0x7F
            }
        }
    }
    
    func dist(_ A: PixelValue, _ B: PixelValue) -> Float {
        let Ar = Float(A.r) / 255.0
        let Ag = Float(A.g) / 255.0
        let Ab = Float(A.b) / 255.0
        let Br = Float(B.r) / 255.0
        let Bg = Float(B.g) / 255.0
        let Bb = Float(B.b) / 255.0
        
        let rawDistCubed = ((Ar - Br) * (Ar - Br)) + ((Ag - Bg) * (Ag - Bg)) + ((Ab - Bb) * (Ab - Bb))
        return rawDistCubed / 3.0 // 3 is the absolute max we could get in rawDistCubed, so let's do a simple/dumb optimization and forgo the cube root
    }
    
    func regionToImage() -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.none.rawValue
        let context = CGContext(data: regionDataPtr, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: Int(imageSize.width), space: colorSpace, bitmapInfo: bitmapInfo)!
        let cgImage = context.makeImage()!
        return UIImage(cgImage: cgImage)
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

class ImageEditorViewController: UIViewController, DrawMaskViewDelegate {
    
    enum EditMode {
        case magicWand
        case lasso
    }
    
    var editMode = EditMode.magicWand
    
    var image : UIImage! = nil
    var filter = ChromaKeyFilter()
    var sampler : ImageSampler! = nil
    
    var maskPath : UIBezierPath? = nil
    
//    var regionGrower : RegionGrower! = nil
//    var seedPt : CGPoint! = nil
    
    @IBOutlet weak var imageView: UIImageView!
//    @IBOutlet weak var selectionImageView: UIImageView!
//    @IBOutlet weak var colorView: ColorView!
    @IBOutlet weak var drawMaskView: DrawMaskView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawMaskView.delegate = self
        
        if nil != image {
            imageView.image = image
            sampler = ImageSampler(image: image)
//            regionGrower = RegionGrower(image: image)
            filter.input = CIImage(image: image)!
            filter.chromaColor = SIMD3<Float>(0, 1.0, 0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        setupUiForMode(.magicWand)
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
//            colorView.color = pickedColor
//            colorView.setNeedsDisplay()
            filter.chromaColor = SIMD3<Float>(Float(pixelColor.r) / 255.0, Float(pixelColor.g) / 255.0, Float(pixelColor.b) / 255.0)
            filter.threshold = 0.0
            imageView.image = UIImage(ciImage: filter.outputImage!)
//            seedPt = convertedPt
//            regionGrower.search(seed: seedPt, threshold: 0.3)
//            selectionImageView.image = regionGrower.regionToImage()
            
        case .changed:
            let dist = sender.distance
            let width = imageView.bounds.width
            filter.threshold = clamp(Float(dist / (width / 2.0)), 0, 1.0)
            imageView.image = UIImage(ciImage: filter.outputImage!)
//            let threshold = clamp(Float(dist / (width / 2.0)), 0, 1.0)
//            print("Threshold: \(threshold)")
//            regionGrower.search(seed: seedPt, threshold: threshold)
//            imageView.image = regionGrower.regionToImage()
        case .ended: break
        default: break
        }
    }
    
    func setupUiForMode(_ mode: EditMode) {
        if mode == .magicWand {
            drawMaskView.isHidden = true
            drawMaskView.clearMask()
            imageView.image = image
        }
        else if mode == .lasso {
            filter.threshold = 0.0
            imageView.image = UIImage(ciImage: filter.outputImage!)
            drawMaskView.clearMask()
            drawMaskView.isHidden = false
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController!.popViewController(animated: true)
    }
    
    @IBAction func toolControlTapped(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Magic Wand
            if editMode != .magicWand {
                editMode = .magicWand
                setupUiForMode(.magicWand)
            }
        }
        else {
            // Lasso
            if editMode != .lasso {
                editMode = .lasso
                setupUiForMode(.lasso)
            }
        }
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        var img : UIImage! = nil
        if editMode == .magicWand {
            img = UIImage(ciImage: filter.outputImage!)
        }
        else if editMode == .lasso {
            if let mask = maskPath {
                img = createImageWithMask(mask: mask, crop: true)
            }
            else {
                img = image
            }
        }
        
        
        let project = createProjectWithImage(img, in: AotStore)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let scratchVC = storyboard.instantiateViewController(withIdentifier: "Scratch") as! ScratchViewController
        scratchVC.project = project
        navigationController!.setViewControllers([navigationController!.viewControllers[0], scratchVC], animated: true)
    }
    
    func createImageWithMask(mask: UIBezierPath, crop: Bool = false) -> UIImage {
        let imageRect = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        let scale = image.size.width / imageRect.size.width
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let translationTransform = CGAffineTransform(translationX: -imageRect.origin.x, y: -imageRect.origin.y)
        var transform = translationTransform.concatenating(scaleTransform)
        let offsetPath = mask.cgPath.copy(using: &transform)!
        
        UIGraphicsBeginImageContext(image.size)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.addPath(offsetPath)
        ctx.clip()
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        var maskedImg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        if crop {
            let cropped = maskedImg.cgImage!.cropping(to: offsetPath.boundingBoxOfPath)!
            maskedImg = UIImage(cgImage: cropped)
        }
        
        return maskedImg
    }
    
    func drawMaskViewUpdatedMask(_ maskView: DrawMaskView, _ path: UIBezierPath?) {
        if let newPath = path {
            maskPath = newPath
            imageView.image = createImageWithMask(mask: newPath)
        }
        else {
            maskPath = nil
            imageView.image = image
        }
    }
    
}
