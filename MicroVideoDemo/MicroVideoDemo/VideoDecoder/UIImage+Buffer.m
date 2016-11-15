//
//  UIImage+Buffer.m
//  小视频播放
//
//  Created by 陈琪 on 15/12/14.
//  Copyright © 2015年 陈琪. All rights reserved.
//

#import "UIImage+Buffer.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (Buffer)

// AVFoundation 捕捉视频帧，很多时候都需要把某一帧转换成 image
+ (CGImageRef)cgImageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef
{
    return [self cgImageFromSampleBufferRef:sampleBufferRef orientation:UIImageOrientationUp];
}

+ (CGImageRef)cgImageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef orientation:(UIImageOrientation)orientation
{
    CGImageRef quartzImage;
    // 为媒体数据设置一个CMSampleBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    // 锁定 pixel buffer 的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到 pixel buffer 的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到 pixel buffer 的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到 pixel buffer 的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的 RGB 颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphic context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    //根据这个位图 context 中的像素创建一个 Quartz image 对象
    quartzImage = CGBitmapContextCreateImage(context);
    
    // 解锁 pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // 释放 context 和颜色空间
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);

    /** 更正视频图片显示 */
//    if (orientation != UIImageOrientationUp) {
//        UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1 orientation:orientation];
//        CGImageRelease(quartzImage);
//        quartzImage = [image cgFixOrientation];
//        image = nil;
//    }
    
    // 用 Quzetz image 创建一个 UIImage 对象
    // UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放 Quartz image 对象
    //    CGImageRelease(quartzImage);
    
    return quartzImage;
}

+ (UIImage *)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef
{
    CGImageRef cgImage = [self cgImageFromSampleBufferRef:sampleBufferRef];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}
@end
