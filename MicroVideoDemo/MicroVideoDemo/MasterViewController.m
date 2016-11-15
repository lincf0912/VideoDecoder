//
//  MasterViewController.m
//  MicroVideoDemo
//
//  Created by LamTsanFeng on 2016/11/15.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "MasterViewController.h"
#import "VideoDecoder.h"
#import "VideoCell.h"

#define kCellClass @"VideoCell"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /** 注册cell */
    [self.tableView registerClass:NSClassFromString(kCellClass) forCellReuseIdentifier:kCellClass];
    
    self.objects = [@[] mutableCopy];
    /** 数据源 */
    for (NSInteger i=1; i<7; i++) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"%ld", i] withExtension:@"mp4"];
        [self.objects addObject:url];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[VideoDecoder sharePlayVideoManagement] cancelAllQueue];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /** 当前显示cell是否存在视频，存在reloadRowsAtIndexPaths */
//    self.tableView.visibleCells
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellClass forIndexPath:indexPath];

    NSURL *videoUrl = self.objects[indexPath.row];
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%ld.png", indexPath.row+1]];
    
    [cell setVideoUrl:videoUrl placeholderImage:image];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [VideoCell getCellHeight];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"tracking:%d,--dragging:%d,--decelerating:%d", tableView.tracking, tableView.dragging, tableView.decelerating);
    
    if (tableView.dragging) {
        NSURL *videoUrl = self.objects[indexPath.row];
        /** 滑动取消播放 */
        [[VideoDecoder sharePlayVideoManagement] cancelQueue:[videoUrl path]];
    }
}


@end
