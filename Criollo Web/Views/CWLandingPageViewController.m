//
//  CWLandingPageViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 2/12/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWLandingPageViewController.h"
#import "CWAppDelegate.h"
#import "CWGithubHelper.h"

@implementation CWLandingPageViewController

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"tagline"] = CWAppDelegate.githubRepo.desc ?: @"";
    return [super presentViewControllerWithRequest:request response:response];
}

@end
