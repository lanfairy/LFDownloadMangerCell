//
//  LFCell.m
//  LFDownloadMangerCell
//
//  Created by 张俊伟 on 16/3/13.
//  Copyright © 2016年 lanfairy. All rights reserved.
//

#import "LFCell.h"
#import "LFDownload.h"
#import "LFProgressView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface LFCell()
@property (strong, nonatomic)  LFProgressView *progressView;
@property (strong, nonatomic)  UIButton *openButton;
@property (strong, nonatomic)  UIButton *downloadButton;
@property (strong, nonatomic)  UILabel *fileText;
@end
@implementation LFCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

+(instancetype)fileCellWithTableView:(UITableView *)tableView
{
    
    static NSString *ID = @"file";
    LFCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil)
    {
        
        cell = [[self alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    
    
    return cell;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
//        self.backgroundColor = [UIColor cyanColor];
        //  progressView
        self.progressView = [[LFProgressView alloc] init];
        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.progressView];
        
        NSString *pvHVfl = @"H:|[_progressView]|";
        NSDictionary *pvViews = NSDictionaryOfVariableBindings(_progressView);
        NSArray *HContrations = [NSLayoutConstraint constraintsWithVisualFormat:pvHVfl options:kNilOptions metrics:nil views:pvViews];
        [self.contentView addConstraints:HContrations];
        
        NSString *pvVVfl = @"V:|-1-[_progressView(2)]";
        NSArray *VContraions = [NSLayoutConstraint constraintsWithVisualFormat:pvVVfl options:kNilOptions metrics:nil views:pvViews];
        [self.contentView addConstraints:VContraions];
        
        
        //  fileText
        self.fileText = [[UILabel alloc] init];
        self.fileText.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.fileText];
        
        
        
        //  downloadButton
        self.downloadButton = [[UIButton alloc] init];
        [self.downloadButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        self.downloadButton.opaque = YES;
        [self.downloadButton addTarget:self action:@selector(download:) forControlEvents:UIControlEventTouchUpInside];
        self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.downloadButton];
        
        NSNumber *margin = @10;
        NSNumber *doubleMargin = @(2*margin.integerValue);
        // 水平方向约束
        NSString *hVfl = @"H:|-margin-[_downloadButton]-doubleMargin-[_fileText]-doubleMargin-|";
        NSDictionary *hViews = NSDictionaryOfVariableBindings(_downloadButton,_fileText);
        NSDictionary *hMertrics = NSDictionaryOfVariableBindings(margin,doubleMargin);
        NSArray *hContrains = [NSLayoutConstraint constraintsWithVisualFormat:hVfl options:kNilOptions metrics:hMertrics views:hViews];
        [self addConstraints:hContrains];
        
        //fileText 垂直居中
        NSLayoutConstraint *fileTextCenterYContraint = [NSLayoutConstraint constraintWithItem:self.fileText attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        [self addConstraint:fileTextCenterYContraint];
        
        
        //downloadButton垂直方向
        NSString *vVfl = @"V:|-margin-[_downloadButton]-margin-|";
        NSArray *vContrains = [NSLayoutConstraint constraintsWithVisualFormat:vVfl options:kNilOptions metrics:hMertrics views:hViews];
        [self addConstraints:vContrains];
        
        NSLayoutConstraint *downloadButtonWidthContraint = [NSLayoutConstraint constraintWithItem:self.downloadButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.downloadButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.f];
        [self.downloadButton addConstraint:downloadButtonWidthContraint];
        
        
        //  openButton
        self.openButton = [[UIButton alloc] init];
        [self.openButton setBackgroundImage:[UIImage imageNamed:@"check"] forState:UIControlStateNormal];
        [self.openButton addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
        self.openButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.openButton];
        
        NSLayoutConstraint *openButtonLeadingContraint = [NSLayoutConstraint constraintWithItem:self.openButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.downloadButton attribute:NSLayoutAttributeLeading multiplier:1.f constant:0];
        NSLayoutConstraint *openButtonTrealingContraint = [NSLayoutConstraint constraintWithItem:self.openButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.downloadButton attribute:NSLayoutAttributeTrailing multiplier:1.f constant:0];
        NSLayoutConstraint *openButtonTopContraint = [NSLayoutConstraint constraintWithItem:self.openButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.downloadButton attribute:NSLayoutAttributeTop multiplier:1.f constant:0];
        NSLayoutConstraint *openButtonBottomContraint = [NSLayoutConstraint constraintWithItem:self.openButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.downloadButton attribute:NSLayoutAttributeBottom multiplier:1.f constant:0];
        [self addConstraints:@[openButtonLeadingContraint, openButtonTrealingContraint, openButtonTopContraint, openButtonBottomContraint]];
        
        
    }
    return self;
}

- (void)setUrl:(NSString *)url
{
    _url = [url copy];
    
    // 设置文字
    self.fileText.text = [url lastPathComponent];
    
    // 控制状态
    LFDownloadInfo *info = [[LFDownloadManager defaultManager] downloadInfoForURL:url];
    
    if (info.state == LFDownloadStateCompleted) {
        self.openButton.hidden = NO;
        self.downloadButton.hidden = YES;
        self.progressView.hidden = YES;
    } else if (info.state == LFDownloadStateWillResume) {
        self.openButton.hidden = YES;
        self.downloadButton.hidden = NO;
        self.progressView.hidden = NO;
        
        [self.downloadButton setBackgroundImage:[UIImage imageNamed:@"clock"] forState:UIControlStateNormal];
    } else {
        self.openButton.hidden = YES;
        self.downloadButton.hidden = NO;
        
        if (info.state == LFDownloadStateNone ) {
            self.progressView.hidden = YES;
        } else {
            self.progressView.hidden = NO;
            
            if (info.totalBytesExpectedToWrite) {
                self.progressView.progress = 1.0 * info.totalBytesWritten / info.totalBytesExpectedToWrite;
            } else {
                self.progressView.progress = 0.0;
            }
        }
        
        if (info.state == LFDownloadStateResumed) {
            [self.downloadButton setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        } else {
            [self.downloadButton setBackgroundImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
        }
    }
}

- (void)download:(UIButton *)sender {
    NSLog(@"%s",__func__);
    LFDownloadInfo *info = [[LFDownloadManager defaultManager] downloadInfoForURL:self.url];
    
    if (info.state == LFDownloadStateResumed || info.state == LFDownloadStateWillResume) {
        [[LFDownloadManager defaultManager] suspend:info.url];
    } else {
        [[LFDownloadManager defaultManager] download:self.url progress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.url = self.url;
            });
        } state:^(LFDownloadState state, NSString *file, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.url = self.url;
            });
        }];
    }
}

- (void)open:(UIButton *)sender {
    LFDownloadInfo *info = [[LFDownloadManager defaultManager] downloadInfoForURL:self.url];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    MPMoviePlayerViewController *mpc = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:info.file]];
    [vc presentViewController:mpc animated:YES completion:nil];
}








@end
