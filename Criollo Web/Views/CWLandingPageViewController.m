//
//  CWLandingPageViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/12/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWLandingPageViewController.h"
#import "AppDelegate.h"

@interface CWLandingPageViewController () {

}

//+ (NSDictionary *) mainMenuItems;

@end

@implementation CWLandingPageViewController

//+ (NSDictionary *)mainMenuItems {
//    static NSDictionary* mainMenuItems;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        mainMenuItems = @{
//            "Getting Started"
//        };
//    });
//    return mainMenuItems;
//}


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
    self.templateVariables[@"token"] = request.cookies[CWSessionCookie] ? : @"";
    self.templateVariables[@"list-id"] = @"";
    self.templateVariables[@"subscribe"] = CWSubscribePath;
    self.templateVariables[@"image"] = [NSString stringWithFormat:@"%@://%@%@%@/criollo-icon-square-padded.png", request.URL.scheme, request.URL.host, request.URL.port ? [NSString stringWithFormat:@":%@", request.URL.port] : @"", CWStaticDirPath];

    return [super presentViewControllerWithRequest:request response:response];
}

@end
