//
//  GrabCutViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 6/9/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import AVFoundation

protocol GrabCutGestureViewDelegate {
    func grabCutGestureViewUpdatedMask(_ gestureView: GrabCutGestureView, backgroundData: UnsafeMutableRawPointer, foregroundData: UnsafeMutableRawPointer)
}

class GrabCutGestureView: UIView {
    
    enum GestureViewMode {
        case background
        case foreground
    }
    
    var delegate: GrabCutGestureViewDelegate? = nil
    
    var mode : GestureViewMode = .background
    let strokeWidth : CGFloat = 10
    var bgdCtx : CGContext! = nil
    var fgdCtx : CGContext! = nil
    
    var path = UIBezierPath()
    
    var shouldInform = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = 600
        let height = 800

        bgdCtx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        fgdCtx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        bgdCtx.setStrokeColor(gray: 1.0, alpha: 1.0)
        fgdCtx.setStrokeColor(gray: 1.0, alpha: 1.0)
    }
    
    override func draw(_ rect: CGRect) {
        if mode == .background {
            UIGraphicsPushContext(bgdCtx)
        }
        else {
            UIGraphicsPushContext(fgdCtx)
        }
        path.lineWidth = strokeWidth
        path.stroke()
        UIGraphicsPopContext()
        
        let drawingCtx = UIGraphicsGetCurrentContext()!
        let drawingRect = AVMakeRect(aspectRatio: CGSize(width: 600, height: 800), insideRect: self.bounds)
        let scale = drawingRect.size.width / 600
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let translationTransform = CGAffineTransform(translationX: -drawingRect.origin.x, y: -drawingRect.origin.y)
        var transform = translationTransform.concatenating(scaleTransform)
        let offsetPath = UIBezierPath(cgPath: path.cgPath.copy(using: &transform)!)
        if mode == .background {
            drawingCtx.setStrokeColor(UIColor.red.cgColor);
        }
        else {
            drawingCtx.setStrokeColor(UIColor.green.cgColor);
        }
        offsetPath.lineWidth = strokeWidth
        offsetPath.stroke()
        
//        let upperRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height / 2.0)
//        let lowerRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.height / 2.0), width: rect.width, height: rect.height / 2.0)
//        drawingCtx.draw(bgdCtx.makeImage()!, in: upperRect)
//        drawingCtx.draw(fgdCtx.makeImage()!, in: lowerRect)
        
        if shouldInform {
            // Clear the visible context after making a stroke, etc
            drawingCtx.clear(self.bounds)
            if let d = delegate {
                d.grabCutGestureViewUpdatedMask(self, backgroundData: bgdCtx.data!, foregroundData: fgdCtx.data!)
            }
        }
        shouldInform = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        let scaledLocation = CGPoint(x: location.x * (600.0 / bounds.width), y: location.y * (800.0 / bounds.height))
        path.removeAllPoints()
        path.move(to: scaledLocation)
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        let scaledLocation = CGPoint(x: location.x * (600.0 / bounds.width), y: location.y * (800.0 / bounds.height))
        path.addLine(to: scaledLocation)
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        shouldInform = true
        setNeedsDisplay()
    }
    
    func clear() {
        path.removeAllPoints()
        setNeedsDisplay()
    }
    
    func clearMasks() {
        clear()
        let rect = CGRect(x: 0, y: 0, width: 600, height: 800)
        bgdCtx.clear(rect)
        fgdCtx.clear(rect)
        setNeedsDisplay()
        if let d = delegate {
            d.grabCutGestureViewUpdatedMask(self, backgroundData: bgdCtx.data!, foregroundData: fgdCtx.data!)
        }
    }
}

class GrabCutViewController: UIViewController, GrabCutGestureViewDelegate {

    var image : UIImage! = nil
    var processedImage : UIImage! = nil
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gestureView: GrabCutGestureView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        processedImage = image
        imageView.image = image
        gestureView.frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        gestureView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController!.popViewController(animated: true)
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        let project = createProjectWithImage(processedImage, in: AotStore)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let scratchVC = storyboard.instantiateViewController(withIdentifier: "Scratch") as! ScratchViewController
        scratchVC.project = project
        navigationController!.setViewControllers([navigationController!.viewControllers[0], scratchVC], animated: true)
    }
    
    @IBAction func toolModeControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Background
            if gestureView.mode != .background {
                gestureView.mode = .background
            }
        }
        else {
            // Foreground
            if gestureView.mode != .foreground {
                gestureView.mode = .foreground
            }
        }
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        gestureView.clearMasks()
    }
    
    func grabCutGestureViewUpdatedMask(_ gestureView: GrabCutGestureView, backgroundData: UnsafeMutableRawPointer, foregroundData: UnsafeMutableRawPointer) {
        processedImage = OpenCVBridge.grabCut(image, withBackgroundData: backgroundData, foregroundData: foregroundData)
        imageView.image = processedImage
    }

}
