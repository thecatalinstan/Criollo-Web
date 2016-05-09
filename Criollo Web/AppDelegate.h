//
//  AppDelegate.h
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#define CWGitHubURL             @"https://github.com/thecatalinstan/Criollo"
#define CWWebGitHubURL          @"https://github.com/thecatalinstan/Criollo-Web"
#define CWSubscribePath         @"/subscribe"
#define CWSessionCookie         @"cwsession"
#define CWStaticDirPath         @"/static"
#define CWCriolloVersion        @"0.1.14"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <CRApplicationDelegate>

+ (NSString *)processName;
+ (NSString *)processRunningTime;

+ (NSString *)requestsServed;

+ (NSString *)criolloVersion;
+ (NSString *)bundleVersion;

+ (NSString *)ETag;

@end
NS_ASSUME_NONNULL_END