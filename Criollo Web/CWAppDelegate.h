//
//  AppDelegate.h
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

@class CWBlog;  

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const CWRoutesChangedNotificationName;

FOUNDATION_EXPORT NSString * const CWGitHubURL;
FOUNDATION_EXPORT NSString * const CWWebGitHubURL;

FOUNDATION_EXPORT NSString * const CWStaticDirPath;
FOUNDATION_EXPORT NSString * const CWLoginPath;


@interface CWAppDelegate : NSObject <CRApplicationDelegate>

+ (NSURL *)baseDirectory;
+ (NSURL *)baseURL;
+ (dispatch_queue_t)backgroundQueue;

+ (NSString *)serverSpecString;

+ (NSString *)processName;
+ (NSString *)processRunningTime;

+ (NSString *)requestsServed;

+ (NSString *)criolloVersion;
+ (NSString *)bundleVersion;

+ (NSString *)ETag;

@end

NS_ASSUME_NONNULL_END
