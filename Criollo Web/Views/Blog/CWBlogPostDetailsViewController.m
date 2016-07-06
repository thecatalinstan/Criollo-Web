//
//  CWBlogPostView.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/04/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <CSOddFormatters/CSOddFormatters.h>

#import "CWBlogPostDetailsViewController.h"
#import "CWBlogPost.h"
#import "CWBlogAuthor.h"

@implementation CWBlogPostDetailsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil post:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil post:(CWBlogPost *)post {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self != nil ) {
        self.post = post;
    }
    return self;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.templateVariables[@"id"] = self.post.objectID.URIRepresentation.absoluteString ? : @"";
    self.templateVariables[@"title"] = self.post.title ? : @"";
    self.templateVariables[@"permalink"] = [NSString stringWithFormat:@"%@://%@%@", request.URL.scheme, request.URL.host, self.post.path] ? : @"";
    self.templateVariables[@"author"] = self.post.author.displayName ? : @"";
    self.templateVariables[@"date"] = self.post.date ? [CSTimeIntervalFormatter stringFromDate:[NSDate date] toDate:self.post.date] : @"";
    self.templateVariables[@"content"] = self.post.rendered_content ? : @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
