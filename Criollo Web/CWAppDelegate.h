//
//  AppDelegate.h
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

@class CWGithubRepo, CWGithubRelease;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const CWRoutesChangedNotificationName;

FOUNDATION_EXPORT NSString * const CWStaticDirPath;
FOUNDATION_EXPORT NSString * const CWLoginPath;


@interface CWAppDelegate : NSObject <CRApplicationDelegate>

@property (class, nonatomic, readonly, strong) dispatch_queue_t backgroundQueue;

@property (class, nonatomic, readonly, strong) NSURL *baseDirectory;
@property (class, nonatomic, readonly, strong) NSURL *baseURL;

@property (class, nonatomic, readonly, strong) NSString *serverSpecString;
@property (class, nonatomic, readonly, strong) NSString *requestsServed;

@property (class, nonatomic, readonly, strong) NSString *processName;
@property (class, nonatomic, readonly, strong) NSString *processRunningTime;
@property (class, nonatomic, readonly, strong) NSString *bundleVersion;

@property (class, nonatomic, readonly, strong) NSString *ETag;

@property (class, nonatomic, readonly, strong) CWGithubRepo *githubRepo;
@property (class, nonatomic, readonly, strong) CWGithubRelease *githubRelease;
@property (class, nonatomic, readonly, strong) CWGithubRepo *webGithubRepo;

@end

NS_ASSUME_NONNULL_END
