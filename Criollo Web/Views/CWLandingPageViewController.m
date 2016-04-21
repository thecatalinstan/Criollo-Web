//
//  CWLandingPageViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/12/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

@import CSOddFormatters;
@import CSSystemInfoHelper;

#import "CWLandingPageViewController.h"
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN
@interface CWLandingPageViewController ()

- (NSString *)processInfo;

@end
NS_ASSUME_NONNULL_END

@implementation CWLandingPageViewController

- (NSString *)processInfo {
    NSString* memoryInfo = [CSSystemInfoHelper sharedHelper].memoryUsageString;
    NSString* processName = [AppDelegate processName];
    NSString* processVersion = [AppDelegate bundleVersion];
    NSString* runningTime = [AppDelegate processRunningTime];
    NSString* unameSystemVersion = [CSSystemInfoHelper sharedHelper].systemVersionString;
    NSString * requestsServed = [AppDelegate requestsServed];
    NSString* processInfo;
    if ( memoryInfo ) {
        processInfo = [NSString stringWithFormat:@"%@ %@ using %@ of memory, running for %@ on %@. Served %@ requests.", processName, processVersion, memoryInfo, runningTime, unameSystemVersion, requestsServed];
    } else {
        processInfo = [NSString stringWithFormat:@"%@ %@, running for %@ on %@. Served %@ requests.", processName, processVersion, runningTime, unameSystemVersion, requestsServed];
    }

    return processInfo;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSString* productTitle = @"Criollo";
    NSString* productSubtitle = @"A powerful Cocoa based web application framework for OS X and iOS.";

    self.templateVariables[@"static-dir"] = CWStaticDirPath;
    self.templateVariables[@"title"] = [productTitle stringByAppendingString:@" - web application framework for OS X and iOS"];
    self.templateVariables[@"meta-description"] = @"Criollo helps create fast standalone web apps that deliver content directly over HTTP or FastCGI. You can write code in Objective-C or Swift, using the technologies you are already familiar with.";
    self.templateVariables[@"meta-keywords"] = @"criollo, objective-c, swift, web, framework, HTTP, FCGI, FastCGI, server";
    self.templateVariables[@"product-title"] = productTitle;
    self.templateVariables[@"product-subtitle"] = productSubtitle;
    self.templateVariables[@"main-menu"] = @"";
    self.templateVariables[@"github-url"] = CWGitHubURL;
    self.templateVariables[@"criollo-web-github-url"] = CWWebGitHubURL;
    self.templateVariables[@"token"] = request.cookies[CWSessionCookie] ? : @"";
    self.templateVariables[@"list-id"] = @"";
    self.templateVariables[@"subscribe"] = CWSubscribePath;
    self.templateVariables[@"image"] = [NSString stringWithFormat:@"%@static/criollo-icon-square-padded.png", request.env[@"REQUEST_URI"]];
    self.templateVariables[@"criollo-ver"] = [AppDelegate criolloVersion];
    self.templateVariables[@"criollo-web-ver"] = [AppDelegate bundleVersion];
    self.templateVariables[@"etag"] = [AppDelegate ETag];
    self.templateVariables[@"process-info"] = self.processInfo;

    return [super presentViewControllerWithRequest:request response:response];
}

@end
