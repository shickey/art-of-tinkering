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


class ImageCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    
    var session : AVCaptureSession! = nil
    var capturePhotoOutput: AVCapturePhotoOutput! = nil
    
    @IBOutlet weak var previewView: CameraPreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            self.setupCaptureSession()
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                }
            }
            
        case .denied: // The user has previously denied access.
            return
        case .restricted: // The user can't grant access due to restrictions.
            return
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let rawOrientation = UIDevice.current.orientation.rawValue
        if let previewConnection = previewView.cameraPreviewLayer.connection {
            if previewConnection.isVideoOrientationSupported {
                previewConnection.videoOrientation = AVCaptureVideoOrientation(rawValue: rawOrientation)!
            }
        }
        if let photoConnection = capturePhotoOutput?.connection(with: .video) {
            if photoConnection.isVideoOrientationSupported {
                photoConnection.videoOrientation = AVCaptureVideoOrientation(rawValue: rawOrientation)!
            }
        }
    }
    
    func setupCaptureSession() {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: nil, position: .back)
        let backCamera = discovery.devices[0]
        
        session = AVCaptureSession()
        session.beginConfiguration()
        
        // @TODO: Test for ability to use this preset, fallback if otherwise
        session.sessionPreset = .vga640x480
        
        // @TODO: This assumes that we actually found a camera at all, which is probably bad
        let input = try! AVCaptureDeviceInput(device: backCamera)
        session.addInput(input)
        
        capturePhotoOutput = AVCapturePhotoOutput()
        session.addOutput(capturePhotoOutput)
        
        session.commitConfiguration()
        
        previewView.cameraPreviewLayer.session = self.session
        
        session.startRunning()
    }
    
    @IBAction func captureButtonPressed(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings()
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let cgImage = photo.cgImageRepresentation()!.takeUnretainedValue()
        let rawOrientation = photo.metadata[kCGImagePropertyOrientation as String] as! NSNumber
        let cgOrientation = CGImagePropertyOrientation(rawValue: rawOrientation.uint32Value)!
        let uiOrientation = UIImage.Orientation(rawValue: Int(cgOrientation.rawValue))!
        let captured = UIImage(cgImage: cgImage, scale: 1.0, orientation: uiOrientation)
        
        //       if let del = delegate {
        //           del.imageCaptureCapturedPhoto(self, image: captured)
        //       }
    }
    
}
