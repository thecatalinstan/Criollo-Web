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


@end
NS_ASSUME_NONNULL_END

@implementation CWLandingPageViewController

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSString* productTitle = @"Criollo";
    NSString* productSubtitle = @"A powerful Cocoa based web application framework for OS X and iOS.";

    self.vars[@"static-dir"] = CWStaticDirPath;
    self.vars[@"title"] = [productTitle stringByAppendingString:@" - web application framework for OS X and iOS"];
    self.vars[@"meta-description"] = @"Criollo helps create fast standalone web apps that deliver content directly over HTTP or FastCGI. You can write code in Objective-C or Swift, using the technologies you are already familiar with.";
    self.vars[@"meta-keywords"] = @"criollo, objective-c, swift, web, framework, HTTP, FCGI, FastCGI, server";
    self.vars[@"product-title"] = productTitle;
    self.vars[@"product-subtitle"] = productSubtitle;
    self.vars[@"main-menu"] = @"";
    self.vars[@"github-url"] = CWGitHubURL;
    self.vars[@"criollo-web-github-url"] = CWWebGitHubURL;
    self.vars[@"list-id"] = @"";
    self.vars[@"subscribe"] = CWSubscribePath;
    static NSString * imagePath;
    if (!imagePath) {
        imagePath = [NSString stringWithFormat:@"%@static/criollo-icon-square-padded.png", request.URL];
    }
    self.vars[@"image"] = imagePath;
    self.vars[@"criollo-ver"] = [AppDelegate criolloVersion];
    self.vars[@"criollo-web-ver"] = [AppDelegate bundleVersion];
    self.vars[@"etag"] = [AppDelegate ETag];

    return [super presentViewControllerWithRequest:request response:response];
}

@end
