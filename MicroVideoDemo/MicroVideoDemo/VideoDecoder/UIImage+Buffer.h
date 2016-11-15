//
//  UIImage+Buffer.h
//  小视频播放
//
//  Created by 陈琪 on 15/12/14.
//  Copyright © 2015年 陈琪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface UIImage (Buffer)
/** 通过视频的一帧 获取对应的CGImageRef*/
+ (CGImageRef)cgImageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef;
+ (CGImageRef)cgImageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef orientation:(UIImageOrientation)orientation;

+ (UIImage *)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef;
@end
