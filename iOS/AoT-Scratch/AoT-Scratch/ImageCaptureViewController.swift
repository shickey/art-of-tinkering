//
//  ImageCaptureViewController.swift
//  AoT-Scratch
//
//  Created by Sean Hickey on 2/28/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

import UIKit
import AVFoundation

class CameraPreviewView : UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}


class ImageCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var projectManager : ProjectManager! = nil
    
    var session : AVCaptureSession! = nil
    var capturePhotoOutput: AVCapturePhotoOutput! = nil
    
    var capturedPhoto : UIImage? = nil
    
    @IBOutlet weak var previewView: CameraPreviewView!
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            DispatchQueue.main.async { // Defer this until the view controller can figure out its window orientation
                self.setupCaptureSession()
            }
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                }
            }
            
        case .denied: // The user has previously denied access.
            // @TODO: Display message to user about how to enable camera again
            return
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            return
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.cameraPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    func setupCaptureSession() {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: nil, position: .back)
        let backCamera = discovery.devices[0]
        
        session = AVCaptureSession()
        session.beginConfiguration()
        
        // @TODO: Test for ability to use this preset, fallback if otherwise
        session.sessionPreset = .photo
        
        // @TODO: This assumes that we actually found a camera at all, which is probably bad
        let input = try! AVCaptureDeviceInput(device: backCamera)
        session.addInput(input)
        
        capturePhotoOutput = AVCapturePhotoOutput()
        session.addOutput(capturePhotoOutput)
        
        session.commitConfiguration()
        
        previewView.cameraPreviewLayer.session = self.session
        
        var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
        if self.windowOrientation != .unknown {
            if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                initialVideoOrientation = videoOrientation
            }
        }
        
        self.previewView.cameraPreviewLayer.connection?.videoOrientation = initialVideoOrientation
        
        session.startRunning()
    }
    
    @IBAction func captureButtonPressed(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings()
        
        let videoPreviewLayerOrientation = previewView.cameraPreviewLayer.connection?.videoOrientation
        if let photoOutputConnection = self.capturePhotoOutput.connection(with: .video) {
            photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
        }
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // @TODO: Once we add front-facing camera, we may need to handle flipped image
        //        orientations as well as the standard ones
        
        
        // Normalize the photo orientation so we NEVER HAVE TO WORRY ABOUT IT AGAIN FOR THE LOVE OF...
        var orientation = CGImagePropertyOrientation.up
        if let orientationValue = photo.metadata["Orientation"] as? NSNumber {
            orientation = CGImagePropertyOrientation(rawValue: orientationValue.uint32Value)!
        }
        
        let cgImage = photo.cgImageRepresentation()!.takeUnretainedValue()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        var imageContext : CGContext! = nil
        if orientation == .up || orientation == .down {
            imageContext = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
        }
        else {
            imageContext = CGContext(data: nil, width: cgImage.height, height: cgImage.width, bitsPerComponent: 8, bytesPerRow: cgImage.height * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
        }
        
        if orientation == .up {
            imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        }
        else if orientation == .right {
            imageContext.translateBy(x: 0, y: CGFloat(cgImage.width))
            imageContext.rotate(by: -.pi / 2.0)
            imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        }
        else if orientation == .down {
            imageContext.translateBy(x: CGFloat(cgImage.width), y: CGFloat(cgImage.height))
            imageContext.rotate(by: .pi)
            imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        }
        else if orientation == .left {
            imageContext.translateBy(x: CGFloat(cgImage.height), y: 0)
            imageContext.rotate(by: .pi / 2.0)
            imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        }

        let outImage = imageContext.makeImage()!
        capturedPhoto = UIImage(cgImage: outImage)
        
        performSegue(withIdentifier: "ToEdit", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imageEditVC = segue.destination as? ImageEditViewController, let photo = capturedPhoto {
            imageEditVC.projectManager = projectManager
            imageEditVC.image = photo
        }
    }
    
}
