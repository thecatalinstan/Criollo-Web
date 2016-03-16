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

NS_ASSUME_NONNULL_BEGIN
@interface AppDelegate : NSObject <CRApplicationDelegate>

+ (nullable NSString *)IPAddress;
+ (NSString *)systemInfo;
+ (NSString *)criolloVersion;
+ (NSString *)bundleVersion;

@end
NS_ASSUME_NONNULL_END