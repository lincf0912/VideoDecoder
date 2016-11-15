//
//  VideoCell.h
//  MicroVideoDemo
//
//  Created by LamTsanFeng on 2016/11/15.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCell : UITableViewCell

+ (CGFloat)getCellHeight;

- (void)setVideoUrl:(NSURL *)url placeholderImage:(UIImage *)image;

@end
