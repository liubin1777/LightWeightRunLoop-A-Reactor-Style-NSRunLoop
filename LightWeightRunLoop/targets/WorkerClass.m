//
//  WorkerClass.m
//  LightWeightRunLoop
//
//  Created by wuyunfeng on 16/9/24.
//  Copyright © 2016年 com.wuyunfeng.open. All rights reserved.
//

#import "WorkerClass.h"
#import "LWRunLoop.h"
#import "NSThread+Looper.h"
#import "NSObject+post.h"
@interface WorkerClass()<LWPortDelegate>

@end

@implementation WorkerClass
{
    LWSocketPort *_distantPort;
    LWSocketPort *_localPort;
    NSThread *_workPortRunLoopThread;
}

- (void)launchThreadWithPort:(LWPort *)port
{
    @autoreleasepool {
        [self prepare:port];
    }
}

- (void)prepare:(LWPort *)port
{
    _workPortRunLoopThread = [NSThread currentThread];
    [NSThread currentThread].name = @"workerPortLoopThread";
    _distantPort = (LWSocketPort *)port;
    _localPort = [[LWSocketPort alloc] initWithTCPPort:8082];
    _localPort.delegate = self;
    [_localPort setType:LWSocketPortRoleTypeFollower];
    //modify bug !!!
    LWRunLoop *_currentRunLoop = [LWRunLoop currentLWRunLoop];
    [_currentRunLoop addPort:_localPort forMode:LWDefaultRunLoop];
    [_currentRunLoop runMode:LWDefaultRunLoop];
}

- (void)sendContent:(NSString *)content
{
    [self postSelector:@selector(actualSendContent:) onThread:_workPortRunLoopThread withObject:content];
}

- (void)actualSendContent:(id)content
{
    int length = (int)[content length];
    NSMutableData *data = [[NSMutableData alloc] init];
    [data appendBytes:&length length:sizeof(int)];
    [data appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    LWPortMessage *message = [[LWPortMessage alloc] initWithSendPort:_localPort receivePort:_distantPort components:data];
    [message sendBeforeDate:0];
}

- (LWPort *)localPort
{
    return _localPort;
}

#pragma mark - LWPortDelegate
- (void)handlePortMessage:(NSData * _Nullable )message
{
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    NSLog(@"**[NSThread name = %@] [leader -> follower : %@] **", [NSThread currentThread].name, msg);
}

@end
