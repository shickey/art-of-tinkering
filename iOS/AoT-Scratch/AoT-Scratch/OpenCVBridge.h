//
//  OpenCVBridge.h
//  AoT-Scratch
//
//  Created by Sean Hickey on 6/8/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

#ifndef OpenCVBridge_h
#define OpenCVBridge_h

#import <Foundation/Foundation.h>

@class UIImage;

@interface OpenCVBridge : NSObject
+ (UIImage *)grabCutUIImage:(UIImage *)uiImage withMaskData:(void *)maskData;
@end

#endif /* OpenCVBridge_h */
