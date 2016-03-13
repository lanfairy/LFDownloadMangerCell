//
//  NSString+LFDownload.h
//  LFDownloadDemo
//
//  Created by elly on 16/3/11.
//  Copyright © 2016年 lanfairy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LFDownload)
/**
 *  在前面拼接caches文件夹
 */
- (NSString *)prependCaches;

/**
 *  生成MD5摘要
 */
- (NSString *)MD5;

/**
 *  文件大小
 */
- (NSInteger)fileSize;

/**
 *  生成编码后的URL
 */
- (NSString *)encodedURL;

@end
