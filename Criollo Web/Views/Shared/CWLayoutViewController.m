//
//  CWLayoutViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWLayoutViewController.h"
#import "CWAppDelegate.h"
#import "CWBlog.h"
#import "CWGithubHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface CWLayoutViewController ()

@end

NS_ASSUME_NONNULL_END

@implementation CWLayoutViewController

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSString* productTitle = @"Criollo";

    // These vars might be overriden by subclasses
    self.vars[@"title"] = self.vars[@"title"] ? : [productTitle stringByAppendingString:@" web application framework for macOS, iOS and tvOS"];
    self.vars[@"meta-description"] = self.vars[@"meta-description"] ? : @"Criollo helps create fast standalone web apps that deliver content directly over HTTP or FastCGI. You can write code in Objective-C or Swift, using the technologies you are already familiar with.";
    self.vars[@"meta-keywords"] = @"criollo, objective-c, swift, web, framework, HTTP, FCGI, FastCGI, server";
    self.vars[@"url"] = self.vars[@"url"] ? : request.env[@"REQUEST_URI"];
    self.vars[@"og-type"] = self.vars[@"og-type"] ? : @"website";
    self.vars[@"blogFeedPath"] = self.vars[@"blogFeedPath"] ? : [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", CWBlogPath, CWBlogFeedPath] relativeToURL:[CWAppDelegate baseURL]].absoluteString;
    self.vars[@"image"] = self.vars[@"image"] ? : [NSURL URLWithString:[NSString stringWithFormat:@"%@/criollo-icon-square-padded.png", CWStaticDirPath] relativeToURL:CWAppDelegate.baseURL].absoluteString;

    // These vars are not overriden
    self.vars[@"github-url"] = CWAppDelegate.githubRepo.htmlUrl;
    self.vars[@"criollo-web-github-url"] = CWWebGitHubURL;
    self.vars[@"static-dir"] = CWStaticDirPath;
    self.vars[@"criollo-ver"] = CWAppDelegate.githubRelease.name;
    self.vars[@"criollo-web-ver"] = [CWAppDelegate bundleVersion];
    self.vars[@"etag"] = [CWAppDelegate ETag];
    self.vars[@"redirect"] = request.query[@"redirect"] ? : @"";
    self.vars[@"year"] = @([NSCalendar.currentCalendar component:NSCalendarUnitYear fromDate:NSDate.date]).stringValue;

    return [super presentViewControllerWithRequest:request response:response];

}

@end
