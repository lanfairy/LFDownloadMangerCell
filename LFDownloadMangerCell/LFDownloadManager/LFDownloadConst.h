//
//  LFDownloadConst.h
//  LFDownloadDemo
//
//  Created by elly on 16/3/11.
//  Copyright © 2016年 lanfairy. All rights reserved.
//
#import <Foundation/Foundation.h>

/******** 通知 Begin ********/
/** 下载进度发生改变的通知 */
extern NSString * const LFDownloadProgressDidChangeNotification;
/** 下载状态发生改变的通知 */
extern NSString * const LFDownloadStateDidChangeNotification;
/** 利用这个key从通知中取出对应的LFDownloadInfo对象 */
extern NSString * const LFDownloadInfoKey;

#define LFDownloadNoteCenter [NSNotificationCenter defaultCenter]
/******** 通知 End ********/