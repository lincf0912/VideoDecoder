//
//  VideoDecoder.m
//  MicroVideoDemo
//
//  Created by LamTsanFeng on 2016/11/15.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "VideoDecoder.h"

#import "UIImage+Buffer.h"

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@interface VideoOperation : NSBlockOperation

@property (nonatomic, copy) VideoExecution executionBlock;
@property (nonatomic, copy) VideoComplete completeBlock;
@property (nonatomic, copy) VideoFail failBlock;

@property (nonatomic, readonly) NSString *path;

@end

@implementation VideoOperation

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
        self.name = path;
    }
    return self;
}

- (void)startExecutionBlock {
    __weak typeof(self) weakSelf = self;
    [self addExecutionBlock:^{
        [weakSelf analysisVideo];
    }];
    [self setCompletionBlock:^{
        /** isCancelled触发有延迟，是异步调用，即使回调也不一定准确。 */
        if (weakSelf.completeBlock) weakSelf.completeBlock(weakSelf.path, weakSelf.isCancelled);
    }];
}

#pragma mark - 解析小视频
- (void)analysisVideo
{
    //    DLog(@"运行解析小视频：%@", [_path lastPathComponent]);
    // 获取媒体文件路径的 URL，必须用 fileURLWithPath: 来获取文件 URL
    NSURL *fileUrl = [NSURL fileURLWithPath:_path];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileUrl options:nil];
    NSError *error = nil;
    //    2.创建一个读取媒体数据的阅读器AVAssetReader
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    //    3.获取视频的轨迹AVAssetTrack其实就是我们的视频来源
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    if (videoTracks.count && error == nil) {
        
        AVAssetTrack *videoTrack = [videoTracks firstObject];
        
//        UIImageOrientation orientation = [VideoUtils orientationFromAVAssetTrack:videoTrack];
        
        int m_pixelFormatType;
        //     视频播放时，
        m_pixelFormatType = kCVPixelFormatType_32BGRA;
        // 其他用途，如视频压缩
        //    m_pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        
        //    为我们的阅读器AVAssetReader进行配置，如配置读取的像素，视频压缩等等，得到我们的输出端口videoReaderOutput轨迹，也就是我们的数据来源
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
        
        //    为阅读器添加输出端口，并开启阅读器
        [reader addOutput:videoReaderOutput];
        [reader startReading];
        
        /** 一张图片需要的时间(秒) */
        NSTimeInterval timeInterval = videoTrack.minFrameDuration.value * 1.0 / videoTrack.minFrameDuration.timescale;
        
        //    long time = asset.duration.value / asset.duration.timescale;
        //    NSLog(@"总时间:%ld  每张时间:%f", time, timeInterval);
        
        //    __block NSInteger count = 0;
        
        // 要确保nominalFrameRate>0，之前出现过android拍的0帧视频
        while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0 && ![self isCancelled]) {
            
            // 读取 video sample
            CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
            
            
            /** 存储视频每一帧*/
            if (videoBuffer != nil) {
                //            count++;
                
                CGImageRef cgimage = [UIImage cgImageFromSampleBufferRef:videoBuffer];
                /** 转换为可使用对象*/
                if (cgimage) {
                    __weak typeof(self) weakSelf = self;
                    dispatch_main_async_safe(^{
                        if (weakSelf.executionBlock) weakSelf.executionBlock(cgimage, weakSelf.path);
                        CGImageRelease(cgimage);
                    });
                }
                CFRelease(videoBuffer); /** 必须放在此处释放，因为videoBuffer可能为空如果释放会造成闪退*/
            } else {
                //            NSLog(@"图片数量:%ld", (long)count);
            }
            
            // 根据需要休眠一段时间；比如上层播放视频时每帧之间是有间隔的
            [NSThread sleepForTimeInterval:timeInterval];
        }
        [reader cancelReading];
    } else {
        NSLog(@"小视频不存在视频轨迹，解析失败。%@", error.localizedDescription);
        [self setCompleteBlock:nil];
        __weak typeof(self) weakSelf = self;
        dispatch_main_async_safe(^{
            if (weakSelf.failBlock) weakSelf.failBlock(weakSelf.path);
        });
    }
    //    DLog(@"小视频完成--：%@ 大小:%lldK", [_path lastPathComponent],[FileUtility fileSizeForPath:_path] / 1024);
}


@end



@interface VideoDecoder (){
    NSOperationQueue *queue;
}

@property (nonatomic, strong) NSMutableDictionary *operationDic;

@end
@implementation VideoDecoder


#pragma mark - 单列
+ (instancetype)sharePlayVideoManagement{
    static VideoDecoder *decoder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        decoder = [[self alloc] init];
    });
    return decoder;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount:3];
        _operationDic = [NSMutableDictionary dictionary];
    }return self;
}

#pragma mark - 取消转码
- (void)cancelQueue:(NSString *)path
{
    if (path.length == 0) return;
    VideoOperation *operation = (VideoOperation *)_operationDic[path];
    [operation setExecutionBlock:nil];
    [operation setCompletionBlock:nil];
    if (operation.completeBlock) operation.completeBlock(path, YES);
    [operation cancel];
}

- (void)cancelAllQueue;
{
    [_operationDic removeAllObjects];
    [queue cancelAllOperations];
}

- (void)transformViedoPathToSampBufferRef:(NSString *)videoPath execution:(VideoExecution)executionBlock complete:(VideoComplete)completeBlock fail:(VideoFail)failBlock
{
    NSString *_currentDecodeFilePath = [videoPath copy];
    if (_currentDecodeFilePath && executionBlock) {
        
        /** 地址不存在，不操作 */
        if ([[NSFileManager defaultManager] fileExistsAtPath:_currentDecodeFilePath] == NO) return;
        
        VideoOperation *operation = [_operationDic objectForKey:_currentDecodeFilePath];
        
        /** 是否需要创建线程 */
        if (operation == nil) {
            operation = [[VideoOperation alloc] initWithPath:_currentDecodeFilePath];
            [operation startExecutionBlock];
            [_operationDic setObject:operation forKey:_currentDecodeFilePath];
            [queue addOperation:operation];
        }
        
        operation.executionBlock = executionBlock;
        
        VideoComplete copyCompleteBlock = [completeBlock copy];
        __weak typeof(self) weakSelf = self;
        [operation setCompleteBlock:^(NSString *path, BOOL isCancel) {
            /** 因为operation自身的completionBlock使用主线程，导致自身早已被释放无法回调，必须在这里添加线程 */
            dispatch_main_async_safe(^{
                [weakSelf.operationDic removeObjectForKey:path];
                if (copyCompleteBlock) copyCompleteBlock(path, isCancel);
            });
        }];
        
        VideoFail copyFailBlock = [failBlock copy];
        [operation setFailBlock:^(NSString *path) {
            [weakSelf.operationDic removeObjectForKey:path];
            if (copyFailBlock) copyFailBlock(path);
        }];
        
        
    } else {
        NSLog(@"小视频没有运行解析操作");
    }
}

@end
