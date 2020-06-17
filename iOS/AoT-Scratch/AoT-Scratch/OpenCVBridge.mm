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
                                      kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
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

+ (UIImage *)grabCutUIImage:(UIImage *)uiImage withMaskData:(void *)maskData {
    cv::Mat img = cvMatFromUIImage(uiImage);
    cv::cvtColor(img, img, cv::COLOR_RGBA2RGB);
    
    cv::Mat1b markers(img.rows, img.cols);
    markers.setTo(cv::GC_PR_FGD);
    
    cv::Mat1b bg_seed = markers(cv::Range(0, 5),cv::Range::all());
    bg_seed.setTo(cv::GC_BGD);
    
//    uint8_t *maskPixels = (uint8_t *)maskData;
//    for (int i = 0; i < img.rows * img.cols; ++i) {
//        if (maskPixels[i] > 0) {
//            markers
//        }
//    }
    
    cv::Mat maskMat(img.rows, img.cols, CV_8UC1, maskData);
    cv::Mat flippedMask(img.rows, img.cols, CV_8UC1);
    cv::flip(maskMat, flippedMask, 0); // Flip vertically
    markers.setTo(cv::GC_BGD, flippedMask);
    
//    // cut out a small area in the middle of the image
//    int m_rows = 0.1 * img.rows;
//    int m_cols = 0.1 * img.cols;
//    // of course here you could also use cv::Rect() instead of cv::Range to select 
//    // the region of interest
//    cv::Mat1b fg_seed = markers(cv::Range(img.rows/2 - m_rows/2, img.rows/2 + m_rows/2), 
//                                cv::Range(img.cols/2 - m_cols/2, img.cols/2 + m_cols/2));
//    // mark it as foreground
//    fg_seed.setTo(cv::GC_FGD);
    
    cv::Mat fgd, bgd;
    
//    cv::Rect rect = cv::Rect(10, 10, uiImage.size.width - 10, uiImage.size.height - 10);
    
    cv::grabCut(img, markers, cv::Rect(), bgd, fgd, 1, cv::GC_INIT_WITH_MASK);
    
//    for (int i = 0; i < img.rows; i++) {
//        for (int j = 0; j < img.cols; j++) {
//            if (mask.ptr(i, j)[0] == 0 || mask.ptr(i, j)[0] == 2) {
//                img.ptr(i, j)[0] = 0;
//                img.ptr(i, j)[1] = 0;
//                img.ptr(i, j)[2] = 0;
//            }
//        }
//    }
    
    // let's get all foreground and possible foreground pixels
    cv::Mat1b mask_fgpf = ( markers == cv::GC_FGD) | ( markers == cv::GC_PR_FGD);
    // and copy all the foreground-pixels to a temporary image
    cv::Mat3b tmp = cv::Mat3b::zeros(img.rows, img.cols);
    img.copyTo(tmp, mask_fgpf);
    
    UIImage *result = UIImageFromCVMat(tmp);
    return result;
}

@end


