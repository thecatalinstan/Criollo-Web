//
//  CWLayoutViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWLayoutViewController.h"
#import "CWAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN
@interface CWLayoutViewController ()

@end
NS_ASSUME_NONNULL_END

@implementation CWLayoutViewController

static NSString * imagePath;

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSString* productTitle = @"Criollo";

    self.vars[@"title"] = self.vars[@"title"] ? : [productTitle stringByAppendingString:@" - web application framework for macOS and iOS"];
    self.vars[@"meta-description"] = @"Criollo helps create fast standalone web apps that deliver content directly over HTTP or FastCGI. You can write code in Objective-C or Swift, using the technologies you are already familiar with.";
    self.vars[@"meta-keywords"] = @"criollo, objective-c, swift, web, framework, HTTP, FCGI, FastCGI, server";
    self.vars[@"github-url"] = CWGitHubURL;
    self.vars[@"criollo-web-github-url"] = CWWebGitHubURL;
    if (!imagePath) {
        imagePath = [NSString stringWithFormat:@"%@static/criollo-icon-square-padded.png", request.URL];
    }
    self.vars[@"static-dir"] = CWStaticDirPath;
    self.vars[@"image"] = imagePath;
    self.vars[@"criollo-ver"] = [CWAppDelegate criolloVersion];
    self.vars[@"criollo-web-ver"] = [CWAppDelegate bundleVersion];
    self.vars[@"etag"] = [CWAppDelegate ETag];
    self.vars[@"redirect"] = request.query[@"redirect"] ? : @"";

    return [super presentViewControllerWithRequest:request response:response];

}

@end
