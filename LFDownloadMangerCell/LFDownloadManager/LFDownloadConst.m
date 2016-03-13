//
//  LFDownloadConst.m
//  LFDownloadDemo
//
//  Created by elly on 16/3/11.
//  Copyright © 2016年 lanfairy. All rights reserved.
//
#import <Foundation/Foundation.h>

/******** 通知 Begin ********/
/** 下载进度发生改变的通知 */
NSString * const LFDownloadProgressDidChangeNotification = @"LFDownloadProgressDidChangeNotification";
/** 下载状态发生改变的通知 */
NSString * const LFDownloadStateDidChangeNotification = @"LFDownloadStateDidChangeNotification";
/** 利用这个key从通知中取出对应的LFDownloadInfo对象 */
NSString * const LFDownloadInfoKey = @"LFDownloadInfoKey";
/******** 通知 End ********/