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
    func grabCutGestureViewUpdatedMask(_ gestureView: GrabCutGestureView, maskData: UnsafeMutableRawPointer)
}

class GrabCutGestureView: UIView {
    
    var delegate: GrabCutGestureViewDelegate? = nil
    
    let strokeWidth : CGFloat = 10;
    var ctx : CGContext! = nil
    
    var path = UIBezierPath()
    
    var shouldInform = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = 600
        let height = 800

        ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        ctx.setStrokeColor(gray: 1.0, alpha: 1.0)
    }
    
    override func draw(_ rect: CGRect) {
        UIGraphicsPushContext(ctx)
        path.lineWidth = strokeWidth
        path.stroke()
        UIGraphicsPopContext()
        
        let drawingCtx = UIGraphicsGetCurrentContext()!
        drawingCtx.draw(ctx.makeImage()!, in: rect)
        
        if shouldInform {
            if let d = delegate {
                d.grabCutGestureViewUpdatedMask(self, maskData: ctx.data!)
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
    
    func grabCutGestureViewUpdatedMask(_ gestureView: GrabCutGestureView, maskData: UnsafeMutableRawPointer) {
        processedImage = OpenCVBridge.grabCut(image, withMaskData: maskData)
        imageView.image = processedImage
    }

}
