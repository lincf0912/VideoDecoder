//
//  VideoDecoder.h
//  MicroVideoDemo
//
//  Created by LamTsanFeng on 2016/11/15.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef void (^VideoExecution) (CGImageRef imageData, NSString *path);
typedef void (^VideoComplete) (NSString *path, BOOL isCancel);
typedef void (^VideoFail) (NSString *path);

@interface VideoDecoder : NSObject

/** 单列 */
+ (instancetype)sharePlayVideoManagement;

/**
 *  @author lincf, 16-05-27 09:05:59
 *
 *  解析视频 转换为 组成视频的图片
 *
 *  @param videoPath      视频路径
 *  @param executionBlock 进行时 一直返回视频图片，直到解析完毕
 *  @param completeBlock  完成时 解析完毕调用（包含进行时被停止）
 *  @param failBlock      失败情况（视频出现问题无法解析）
 */
- (void)transformViedoPathToSampBufferRef:(NSString *)videoPath execution:(VideoExecution)executionBlock complete:(VideoComplete)completeBlock fail:(VideoFail)failBlock;


/** 停止播放 */
- (void)cancelAllQueue;
/** 取消播放 */
- (void)cancelQueue:(NSString *)path;
/** 是否播放 */
- (BOOL)isTransromVideo:(NSString *)path;

@end
