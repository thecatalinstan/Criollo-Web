//
//  CWLayoutViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWLayoutViewController.h"
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN
@interface CWLayoutViewController ()

@end
NS_ASSUME_NONNULL_END

@implementation CWLayoutViewController

static NSString * imagePath;

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSString* productTitle = @"Criollo";

    self.templateVariables[@"title"] = [productTitle stringByAppendingString:@" - web application framework for OS X and iOS"];
    self.templateVariables[@"meta-description"] = @"Criollo helps create fast standalone web apps that deliver content directly over HTTP or FastCGI. You can write code in Objective-C or Swift, using the technologies you are already familiar with.";
    self.templateVariables[@"meta-keywords"] = @"criollo, objective-c, swift, web, framework, HTTP, FCGI, FastCGI, server";
    self.templateVariables[@"github-url"] = CWGitHubURL;
    self.templateVariables[@"criollo-web-github-url"] = CWWebGitHubURL;
    if (!imagePath) {
        imagePath = [NSString stringWithFormat:@"%@static/criollo-icon-square-padded.png", request.URL];
    }
    self.templateVariables[@"static-dir"] = CWStaticDirPath;
    self.templateVariables[@"image"] = imagePath;
    self.templateVariables[@"criollo-ver"] = [AppDelegate criolloVersion];
    self.templateVariables[@"criollo-web-ver"] = [AppDelegate bundleVersion];
    self.templateVariables[@"etag"] = [AppDelegate ETag];

    return [super presentViewControllerWithRequest:request response:response];

}

@end
