//
//  ChromaKeyFilter.swift
//  Scraptchure
//
//  Created by Sean Hickey on 10/11/19.
//  Copyright © 2019 Massachusetts Institute of Technology. All rights reserved.
//

import CoreImage
import simd

class ChromaKeyFilter : CIFilter {
    
    var chromaKernel : CIKernel! = nil
    var input : CIImage! = nil
    var chromaColor : SIMD3<Float>! = SIMD3<Float>(x: 0, y: 0, z: 0)
    var threshold : Float = 0.0;
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        if chromaKernel == nil {
            let libraryData = try! Data(contentsOf: Bundle.main.url(forResource: "default", withExtension: "metallib")!)
            chromaKernel = try! CIKernel(functionName: "chromaKey", fromMetalLibraryData: libraryData)
        }
        super.init()
    }
    
    override var outputImage: CIImage? {
        let roiCallback = { (index : Int32, rect: CGRect) -> CGRect in return rect }
        let chromaVec = CIVector(x: CGFloat(chromaColor!.x), y: CGFloat(chromaColor!.y), z: CGFloat(chromaColor!.z))
        return chromaKernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [input!, chromaVec, threshold])
    }
    
}
