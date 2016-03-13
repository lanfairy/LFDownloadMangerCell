//
//  LFFileListViewController.m
//  LFDownloadMangerCell
//
//  Created by 张俊伟 on 16/3/13.
//  Copyright © 2016年 lanfairy. All rights reserved.
//

#import "LFFileListViewController.h"
#import "LFCell.h"
#import "LFDownload.h"

@interface LFFileListViewController ()
@property (strong, nonatomic) NSMutableArray *urls;
@end

@implementation LFFileListViewController
//全部暂停
- (void)suspendAll {
    
    [[LFDownloadManager defaultManager] suspendAll];
}
// 全部开始下载  全部继续下载
- (void)downloadAndResumeAll {
    static BOOL isHaveDownloadtask = NO;
    //没有下载任务时
    if (!isHaveDownloadtask) {
        for (int i = 0; i < self.urls.count; i++) {
            LFCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
            [cell download:nil];
        }
        isHaveDownloadtask = YES;
        [self.navigationItem.rightBarButtonItem setTitle:@"全部继续"];
    } else {
        
        [[LFDownloadManager defaultManager] resumeAll];
    }
    
}

- (NSMutableArray *)urls
{
    if (!_urls) {
        self.urls = [NSMutableArray array];
        for (int i = 1; i<=10; i++) {
            [self.urls addObject:[NSString stringWithFormat:@"http://120.25.226.186:32812/resources/videos/minion_%02d.mp4", i]];
           
        }
    }
    return _urls;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [LFDownloadManager defaultManager].maxDownloadingCount = 3;
    
    self.tableView.rowHeight = 74;
    
    
    //全部暂停
    UIBarButtonItem *suspendItem = [[UIBarButtonItem alloc]initWithTitle:@"全部暂停" style:UIBarButtonItemStylePlain target:self action:@selector(suspendAll)];
    [self.navigationItem setLeftBarButtonItem:suspendItem];
    
    //全部下载
    UIBarButtonItem *resumeItem = [[UIBarButtonItem alloc] initWithTitle:@"全部开始" style:UIBarButtonItemStylePlain target:self action:@selector(downloadAndResumeAll)];
    
    [self.navigationItem setRightBarButtonItem:resumeItem];
    
    
    
}



#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.urls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    LFCell *cell = [LFCell fileCellWithTableView:tableView];
    cell.url = self.urls[indexPath.row];
    return cell;
}

@end
