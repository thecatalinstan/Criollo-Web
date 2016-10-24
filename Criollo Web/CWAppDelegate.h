//
//  AppDelegate.h
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#define CWRoutesChangedNotificationName     @"CWRoutesChangedNotification"

#define CWGitHubURL                         @"https://github.com/thecatalinstan/Criollo"
#define CWWebGitHubURL                      @"https://github.com/thecatalinstan/Criollo-Web"
#define CWSessionCookie                     @"cwsession"
#define CWCriolloVersion                    @"0.4.9"

#define CWStaticDirPath                     @"/static"
#define CWLoginPath                         @"/login"

@class CWBlog;

NS_ASSUME_NONNULL_BEGIN

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
