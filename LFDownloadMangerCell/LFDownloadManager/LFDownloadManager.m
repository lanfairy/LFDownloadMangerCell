//
//  LFDownloadManager.m
//  LFDownloadDemo
//
//  Created by elly on 16/3/11.
//  Copyright © 2016年 lanfairy. All rights reserved.
//

#import "LFDownloadManager.h"
#import "NSString+LFDownload.h"
#import "LFDownloadConst.h"

/** 存放所有的文件大小 */
static NSMutableDictionary *_totalFileSizes;
/** 存放所有的文件大小的文件路径 */
static NSString *_totalFileSizesFile;

/** 根文件夹 */
static NSString * const LFDownloadRootDir = @"com_lanfairy_www_LFdownload";

/** 默认manager的标识 */
static NSString * const LFDowndloadManagerDefaultIdentifier = @"com.lanfairy.www.downloadmanager";

/****************** LFDownloadInfo Begin ******************/
@interface LFDownloadInfo()
{
    LFDownloadState _state;
    NSInteger _totalBytesWritten;
}
/******** Readonly Begin ********/
/** 下载状态 */
@property (assign, nonatomic) LFDownloadState state;
/** 这次写入的数量 */
@property (assign, nonatomic) NSInteger bytesWritten;
/** 已下载的数量 */
@property (assign, nonatomic) NSInteger totalBytesWritten;
/** 文件的总大小 */
@property (assign, nonatomic) NSInteger totalBytesExpectedToWrite;
/** 文件名 */
@property (copy, nonatomic) NSString *filename;
/** 文件路径 */
@property (copy, nonatomic) NSString *file;
/** 文件url */
@property (copy, nonatomic) NSString *url;
/** 下载的错误信息 */
@property (strong, nonatomic) NSError *error;
/******** Readonly End ********/

/** 存放所有的进度回调 */
@property (copy, nonatomic) LFDownloadProgressChangeBlock progressChangeBlock;
/** 存放所有的完毕回调 */
@property (copy, nonatomic) LFDownloadStateChangeBlock stateChangeBlock;
/** 任务 */
@property (strong, nonatomic) NSURLSessionDataTask *task;
/** 文件流 */
@property (strong, nonatomic) NSOutputStream *stream;
@end

@implementation LFDownloadInfo
- (NSString *)file
{
    if (_file == nil) {
        _file = [[NSString stringWithFormat:@"%@/%@", LFDownloadRootDir, self.filename] prependCaches];
    }
    
    if (_file && ![[NSFileManager defaultManager] fileExistsAtPath:_file]) {
        NSString *dir = [_file stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
//    NSLog(@"file: %@",_file);
    return _file;
}

- (NSString *)filename
{
    if (_filename == nil) {
        NSString *pathExtension = self.url.pathExtension;
        if (pathExtension.length) {
            _filename = [NSString stringWithFormat:@"%@.%@", self.url.MD5, pathExtension];
        } else {
            _filename = self.url.MD5;
        }
    }
//    NSLog(@"fileName: %@",_filename);
    return _filename;
}

- (NSOutputStream *)stream
{
    if (_stream == nil) {
        _stream = [NSOutputStream outputStreamToFileAtPath:self.file append:YES];
    }
    return _stream;
}

- (NSInteger)totalBytesWritten
{
    return self.file.fileSize;
}

- (NSInteger)totalBytesExpectedToWrite
{
    if (!_totalBytesExpectedToWrite) {
        _totalBytesExpectedToWrite = [_totalFileSizes[self.url] integerValue];
    }
    return _totalBytesExpectedToWrite;
}

- (LFDownloadState)state
{
    // 如果是下载完毕
    if (self.totalBytesExpectedToWrite && self.totalBytesWritten == self.totalBytesExpectedToWrite) {
        return LFDownloadStateCompleted;
    }
    
    // 如果下载失败
    if (self.task.error) return LFDownloadStateNone;
    
    return _state;
}

/**
 *  初始化任务
 */
- (void)setupTask:(NSURLSession *)session
{
    if (self.task) return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.totalBytesWritten];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    self.task = [session dataTaskWithRequest:request];
    // 设置描述
    self.task.taskDescription = self.url;
}

/**
 *  通知进度改变
 */
- (void)notifyProgressChange
{
    !self.progressChangeBlock ? : self.progressChangeBlock(self.bytesWritten, self.totalBytesWritten, self.totalBytesExpectedToWrite);
    [LFDownloadNoteCenter postNotificationName:LFDownloadProgressDidChangeNotification
                                        object:self
                                      userInfo:@{LFDownloadInfoKey : self}];
}

/**
 *  通知下载完毕
 */
- (void)notifyStateChange
{
    !self.stateChangeBlock ? : self.stateChangeBlock(self.state, self.file, self.error);
    [LFDownloadNoteCenter postNotificationName:LFDownloadStateDidChangeNotification
                                        object:self
                                      userInfo:@{LFDownloadInfoKey : self}];
}

#pragma mark - 状态控制
- (void)setState:(LFDownloadState)state
{
    LFDownloadState oldState = self.state;
    if (state == oldState) return;
    
    _state = state;
    
    // 发通知
    [self notifyStateChange];
}

/**
 *  取消
 */
- (void)cancel
{
    if (self.state == LFDownloadStateCompleted || self.state == LFDownloadStateNone) return;
    
    [self.task cancel];
    self.state = LFDownloadStateNone;
}

/**
 *  恢复
 */
- (void)resume
{
    if (self.state == LFDownloadStateCompleted || self.state == LFDownloadStateResumed) return;
    
    [self.task resume];
    self.state = LFDownloadStateResumed;
}

/**
 * 等待下载
 */
- (void)willResume
{
    if (self.state == LFDownloadStateCompleted || self.state == LFDownloadStateWillResume) return;
    
    self.state = LFDownloadStateWillResume;
}

/**
 *  暂停
 */
- (void)suspend
{
    if (self.state == LFDownloadStateCompleted || self.state == LFDownloadStateSuspened) return;
    
    if (self.state == LFDownloadStateResumed) { // 如果是正在下载
        [self.task suspend];
        self.state = LFDownloadStateSuspened;
    } else { // 如果是等待下载
        self.state = LFDownloadStateNone;
    }
}

#pragma mark - 代理方法处理
- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    // 获得文件总长度
    if (!self.totalBytesExpectedToWrite) {
        self.totalBytesExpectedToWrite = [response.allHeaderFields[@"Content-Length"] integerValue] + self.totalBytesWritten;
        // 存储文件总长度
        _totalFileSizes[self.url] = @(self.totalBytesExpectedToWrite);
        [_totalFileSizes writeToFile:_totalFileSizesFile atomically:YES];
    }
    
    // 打开流
    [self.stream open];
    
    // 清空错误
    self.error = nil;
}

- (void)didReceiveData:(NSData *)data
{
    // 写数据
    NSInteger result = [self.stream write:data.bytes maxLength:data.length];
    
    if (result == -1) {
        self.error = self.stream.streamError;
        [self.task cancel]; // 取消请求
    }else{
        self.bytesWritten = data.length;
        [self notifyProgressChange]; // 通知进度改变
    }
}

- (void)didCompleteWithError:(NSError *)error
{
    // 关闭流
    [self.stream close];
    self.bytesWritten = 0;
    self.stream = nil;
    self.task = nil;
    
    // 错误(避免nil的error覆盖掉之前设置的self.error)
    self.error = error ? error : self.error;
    
    // 通知(如果下载完毕 或者 下载出错了)
    if (self.state == LFDownloadStateCompleted || error) {
        // 设置状态
        self.state = error ? LFDownloadStateNone : LFDownloadStateCompleted;
    }
}
@end
/****************** LFDownloadInfo End ******************/


/****************** LFDownloadManager Begin ******************/
@interface LFDownloadManager() <NSURLSessionDataDelegate>
/** session */
@property (strong, nonatomic) NSURLSession *session;
/** 存放所有文件的下载信息 */
@property (strong, nonatomic) NSMutableArray *downloadInfoArray;
/** 是否正在批量处理 */
@property (assign, nonatomic, getter=isBatching) BOOL batching;
@end

@implementation LFDownloadManager

/** 存放所有的manager */
static NSMutableDictionary *_managers;
/** 锁 */
static NSRecursiveLock *_lock;

+ (void)initialize
{
    _totalFileSizesFile = [[NSString stringWithFormat:@"%@/%@", LFDownloadRootDir, @"LFDownloadFileSizes.plist".MD5] prependCaches];
    
    _totalFileSizes = [NSMutableDictionary dictionaryWithContentsOfFile:_totalFileSizesFile];
    if (_totalFileSizes == nil) {
        _totalFileSizes = [NSMutableDictionary dictionary];
    }
    
    _managers = [NSMutableDictionary dictionary];
    
    _lock = [[NSRecursiveLock alloc] init];
}

+ (instancetype)defaultManager
{
    return [self managerWithIdentifier:LFDowndloadManagerDefaultIdentifier];
}

+ (instancetype)manager
{
    return [[self alloc] init];
}

+ (instancetype)managerWithIdentifier:(NSString *)identifier
{
    if (identifier == nil) return [self manager];
    
    LFDownloadManager *mgr = _managers[identifier];
    if (!mgr) {
        mgr = [self manager];
        _managers[identifier] = mgr;
    }
    return mgr;
}

#pragma mark - 懒加载
- (NSURLSession *)session
{
    if (!_session) {
        // 配置
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        // session
        self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:self.queue];
    }
    return _session;
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 3;
    }
    return _queue;
}

- (NSMutableArray *)downloadInfoArray
{
    if (!_downloadInfoArray) {
        self.downloadInfoArray = [NSMutableArray array];
    }
    return _downloadInfoArray;
}

#pragma mark - 私有方法

#pragma mark - 公共方法
- (LFDownloadInfo *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath progress:(LFDownloadProgressChangeBlock)progress state:(LFDownloadStateChangeBlock)state
{
    if (url == nil) return nil;
    
    // 下载信息
    LFDownloadInfo *info = [self downloadInfoForURL:url];
    
    // 设置block
    info.progressChangeBlock = progress;
    info.stateChangeBlock = state;
    
    // 设置文件路径
    if (destinationPath) {
        info.file = destinationPath;
        info.filename = [destinationPath lastPathComponent];
    }
    
    // 如果已经下载完毕
    if (info.state == LFDownloadStateCompleted) {
        // 完毕
        [info notifyStateChange];
        return info;
    } else if (info.state == LFDownloadStateResumed) {
        return info;
    }
    
    // 创建任务
    [info setupTask:self.session];
    
    // 开始任务
    [self resume:url];
    
    return info;
}

- (LFDownloadInfo *)download:(NSString *)url progress:(LFDownloadProgressChangeBlock)progress state:(LFDownloadStateChangeBlock)state
{
    return [self download:url toDestinationPath:nil progress:progress state:state];
}

- (LFDownloadInfo *)download:(NSString *)url state:(LFDownloadStateChangeBlock)state
{
    return [self download:url toDestinationPath:nil progress:nil state:state];
}

- (LFDownloadInfo *)download:(NSString *)url
{
    return [self download:url toDestinationPath:nil progress:nil state:nil];
}

#pragma mark - 文件操作
/**
 * 让第一个等待下载的文件开始下载
 */
- (void)resumeFirstWillResume
{
    if (self.isBatching) return;
    
    LFDownloadInfo *willInfo = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", LFDownloadStateWillResume]].firstObject;
    [self resume:willInfo.url];
}

- (void)cancelAll
{
    [self.downloadInfoArray enumerateObjectsUsingBlock:^(LFDownloadInfo *info, NSUInteger idx, BOOL *stop) {
        [self cancel:info.url];
    }];
}

+ (void)cancelAll
{
    [_managers.allValues makeObjectsPerformSelector:@selector(cancelAll)];
}

- (void)suspendAll
{
    self.batching = YES;
    [self.downloadInfoArray enumerateObjectsUsingBlock:^(LFDownloadInfo *info, NSUInteger idx, BOOL *stop) {
        [self suspend:info.url];
    }];
    self.batching = NO;
}

+ (void)suspendAll
{
    [_managers.allValues makeObjectsPerformSelector:@selector(suspendAll)];
}

- (void)resumeAll
{
    

    [self.downloadInfoArray enumerateObjectsUsingBlock:^(LFDownloadInfo *info, NSUInteger idx, BOOL *stop) {
       
        [self resume:info.url];
        
    }];
}

+ (void)resumeAll
{
    [_managers.allValues makeObjectsPerformSelector:@selector(resumeAll)];
}

//- (void)downloaAll
//{
//    
//}
//+ (void)downloadAll
//{
//    [self.down]
//}


- (void)cancel:(NSString *)url
{
    if (url == nil) return;
    
    // 取消
    [[self downloadInfoForURL:url] cancel];
    
    // 这里不需要取出第一个等待下载的，因为调用cancel会触发-URLSession:task:didCompleteWithError:
//    [self resumeFirstWillResume];
}

- (void)suspend:(NSString *)url
{
    if (url == nil) return;
    
    // 暂停
    [[self downloadInfoForURL:url] suspend];
    
    // 取出第一个等待下载的
    [self resumeFirstWillResume];
}

- (void)resume:(NSString *)url
{
    if (url == nil) return;
    
    // 获得下载信息
    LFDownloadInfo *info = [self downloadInfoForURL:url];
    
    // 正在下载的
    NSArray *downloadingDownloadInfoArray = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state==%d", LFDownloadStateResumed]];
    if (self.maxDownloadingCount && downloadingDownloadInfoArray.count == self.maxDownloadingCount) {
        // 等待下载
        [info willResume];
    } else {
        // 继续
        [info resume];
    }
}

#pragma mark - 获得下载信息
- (LFDownloadInfo *)downloadInfoForURL:(NSString *)url
{
    if (url == nil) return nil;
    
    LFDownloadInfo *info = [self.downloadInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"url==%@", url]].firstObject;
    if (info == nil) {
        info = [[LFDownloadInfo alloc] init];
        info.url = url; // 设置url
        [self.downloadInfoArray addObject:info];
    }
    return info;
}

#pragma mark - <NSURLSessionDataDelegate>
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // 获得下载信息
    LFDownloadInfo *info = [self downloadInfoForURL:dataTask.taskDescription];
    
    // 处理响应
    [info didReceiveResponse:response];
    
    // 继续
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // 获得下载信息
    LFDownloadInfo *info = [self downloadInfoForURL:dataTask.taskDescription];
    
    // 处理数据
    [info didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // 获得下载信息
    LFDownloadInfo *info = [self downloadInfoForURL:task.taskDescription];
    
    // 处理结束
    [info didCompleteWithError:error];
    
    // 恢复等待下载的
    [self resumeFirstWillResume];
}
@end
/****************** LFDownloadManager End ******************/
