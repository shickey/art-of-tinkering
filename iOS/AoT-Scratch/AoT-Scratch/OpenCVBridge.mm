//
//  OpenCVBridge.mm
//  AoT-Scratch
//
//  Created by Sean Hickey on 6/8/20.
//  Copyright © 2020 Lifelong Kindergarten. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVBridge.h"
#import <UIKit/UIKit.h>
#import <stdint.h>

cv::Mat cvMatFromUIImage(UIImage * image)
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;

  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                  cols,                       // Width of bitmap
                                                  rows,                       // Height of bitmap
                                                  8,                          // Bits per component
                                                  cvMat.step[0],              // Bytes per row
                                                  colorSpace,                 // Colorspace
                                                  kCGImageAlphaNoneSkipLast |
                                                  kCGBitmapByteOrderDefault); // Bitmap info flags

  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);

  return cvMat;
}

UIImage *UIImageFromCVMat(cv::Mat cvMat)
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;

  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }

  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                      cvMat.rows,                                 //height
                                      8,                                          //bits per component
                                      8 * cvMat.elemSize(),                       //bits per pixel
                                      cvMat.step[0],                              //bytesPerRow
                                      colorSpace,                                 //colorspace
                                      kCGImageAlphaLast|kCGBitmapByteOrderDefault,// bitmap info
                                      provider,                                   //CGDataProviderRef
                                      NULL,                                       //decode
                                      false,                                      //should interpolate
                                      kCGRenderingIntentDefault                   //intent
                                     );


  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);

  return finalImage;
}

@implementation OpenCVBridge

+ (UIImage *)grabCutUIImage:(UIImage *)uiImage withBackgroundData:(void *)bgdData foregroundData:(void *)fgdData {
    cv::Mat img = cvMatFromUIImage(uiImage);
    cv::cvtColor(img, img, cv::COLOR_RGBA2RGB);
    
    cv::Mat1b markers(img.rows, img.cols);
    markers.setTo(cv::GC_PR_FGD);
    
    cv::Mat1b bg_seed = markers(cv::Range(0, 1),cv::Range(0, 1));
    bg_seed.setTo(cv::GC_BGD);
    
    cv::Mat bgdDataMat(img.rows, img.cols, CV_8UC1, bgdData);
    cv::Mat flippedBgdMask(img.rows, img.cols, CV_8UC1);
    cv::flip(bgdDataMat, flippedBgdMask, 0); // Flip vertically
    markers.setTo(cv::GC_BGD, flippedBgdMask);
    
    cv::Mat fgdDataMat(img.rows, img.cols, CV_8UC1, fgdData);
    cv::Mat flippedFgdMask(img.rows, img.cols, CV_8UC1);
    cv::flip(fgdDataMat, flippedFgdMask, 0); // Flip vertically
    markers.setTo(cv::GC_FGD, flippedFgdMask);
    
    cv::Mat fgd, bgd;
    
    cv::grabCut(img, markers, cv::Rect(), bgd, fgd, 1, cv::GC_INIT_WITH_MASK);
    
    // let's get all foreground and possible foreground pixels
    cv::Mat1b mask_fgpf = ( markers == cv::GC_FGD) | ( markers == cv::GC_PR_FGD);
    // and copy all the foreground-pixels to a temporary image
    cv::Mat4b outMat = cv::Mat4b::zeros(img.rows, img.cols);
    cv::Mat combine[] = {img, mask_fgpf};
    int from_to[] = {0, 0, 1, 1, 2, 2, 3, 3};
    cv::mixChannels(combine, 2, &outMat, 1, from_to, 4);
    
    UIImage *result = UIImageFromCVMat(outMat);
    return result;
}

@end


