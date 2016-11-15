//
//  VideoCell.m
//  MicroVideoDemo
//
//  Created by LamTsanFeng on 2016/11/15.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "VideoCell.h"
#import "VideoDecoder.h"

@interface VideoCell ()

@property (nonatomic, strong) UIImageView *videoView;

@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) UIImage *videoImage;

@end

@implementation VideoCell


+ (CGFloat)getCellHeight
{
    return 220;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.videoView.center = self.contentView.center;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
        [self customInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder])
        [self customInit];
    return self;
}

- (void)customInit{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    
    /** UIImageView */
    
    /** 因Demo的视频大小均为 640*480 这里就写死数据，实际情况应该创建model获取大小 */
    CGFloat v_w = 640, v_h = 480, margin = 10;
    CGFloat h = [VideoCell getCellHeight] - margin;
    CGFloat w = v_w * h / v_h;
    
    self.videoView = (UIImageView *)^{
        if (self.videoView == nil) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
            imageView.userInteractionEnabled = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [self.contentView addSubview:imageView];
            return imageView;
        } else {
            return self.videoView;
        }
    }();
}

- (void)setVideoUrl:(NSURL *)url placeholderImage:(UIImage *)image
{
    [self.videoView setImage:image];
    self.videoUrl = url;
    self.videoImage = image;
    
    [self playVideo];
    
}

- (void)playVideo
{
    VideoDecoder *decoder = [VideoDecoder sharePlayVideoManagement];
    __weak typeof(self) weakSelf = self;
    /** 开始解析 */
    [decoder transformViedoPathToSampBufferRef:[self.videoUrl path] execution:^(CGImageRef imageData, NSString *path) {
        if (weakSelf == nil) return ;
        if ([[weakSelf.videoUrl path] isEqualToString:path]) {
            weakSelf.videoView.layer.contents = (__bridge id _Nullable)(imageData);
        }
    } complete:^(NSString *path, BOOL isCancel) {
        if (weakSelf == nil) return ;
        /** 判断是否继续播放 */
        if ([[weakSelf.videoUrl path] isEqualToString:path]) {
            if (isCancel) { /** 被取消播放 */
                /** 设置视频图片 */
                [weakSelf.videoView setImage:weakSelf.videoImage];
            } else {
                /** 重新播放 */
                [weakSelf playVideo];
            }
        }
    } fail:^(NSString *path) {
        if (weakSelf == nil) return ;
        if ([[weakSelf.videoUrl path] isEqualToString:path]) {
            NSLog(@"视频播放失败");
        }
    }];}

@end
