//
//  CWBlogViewController.m
//  Criollo Web
//
//  Created by Cătălin Stan on 09/05/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "CWBlogViewController.h"
#import "CWBlogPostViewController.h"

@implementation CWBlogViewController

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {

    NSMutableString* contents = [NSMutableString string];

    for ( NSUInteger i = 0; i < 5; i++ ) {
        CWBlogPostViewController* postViewController = [[CWBlogPostViewController alloc] initWithNibName:nil bundle:nil];
        postViewController.templateVariables[@"id"] = @(i).stringValue;
        postViewController.templateVariables[@"title"] = [NSString stringWithFormat:@"Post %lu", (unsigned long)i];

        [contents appendString:[postViewController presentViewControllerWithRequest:request response:response]];
    }

    self.templateVariables[@"posts"] = contents;
    self.templateVariables[@"sidebar"] = @"";

    return [super presentViewControllerWithRequest:request response:response];
}

@end
