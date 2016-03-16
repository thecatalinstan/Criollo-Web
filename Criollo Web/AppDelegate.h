//
//  AppDelegate.h
//  Criollo Web
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <Criollo/Criollo.h>

#define CWGitHubURL             @"https://github.com/thecatalinstan/Criollo"
#define CWSubscribePath         @"/subscribe"
#define CWSessionCookie         @"cwsession"
#define CWStaticDirPath         @"/static"

@interface AppDelegate : NSObject <CRApplicationDelegate>

+ (nullable NSString *)IPAddress;
+ (nonnull NSString *)systemInfo;
+ (nonnull NSString *)criolloVersion;

@end

